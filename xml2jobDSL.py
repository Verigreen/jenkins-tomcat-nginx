# !/usr/bin/env python

from lxml import etree
import sys
import string


def loadXml(name):
    tree = etree.parse(name)
    root = tree.getroot()
    return root, tree

def getPaths(root, tree):
    paths = []
    for child in root.getiterator():
        paths.append([tree.getpath(child), child.attrib, list(child), child.text])
    return paths

def getLeafs(paths):
    return [node for node in paths if node[2].__len__() == 0]

def getAttributes(paths, node):
    nodes = [n[0].split('/')[-1] for n in paths]
    attributes = [n[1] for n in paths]
    s = ''
    for key, value in attributes[nodes.index(node)].iteritems():
        s = s + key + ': ' + '\'' + value + '\','
    s = s[:-1]
    if s.__len__() != 0:
        s = '(' + s + ')'
    return s

xmlFile = "/%s/config.xml" % sys.argv[1]

root, tree = loadXml(xmlFile)

paths = getPaths(root, tree)

leafs = getLeafs(paths)

print "job('%s') {\n\tconfigure {\n" % sys.argv[1]

for i in leafs:
    ps = i[0][1:]
    ps = ps.split('/')
    for node in ps:
        ps[ps.index(node)] = "'%s'" % node
    for node in ps:
        ps[ps.index(node)] = node + getAttributes(paths,node.replace("\'", "", 2))
    ps[0] = 'it'
    unicodeText = "%s" % i[3]
    unicodeText = filter(lambda x: x in string.printable, unicodeText) # Remove non-ascii characters
    print "\t\t(%s).value = '%s'" % ('/'.join(ps), unicodeText.replace('\'','').replace('\n','\\n'))

print "\t}\n}"