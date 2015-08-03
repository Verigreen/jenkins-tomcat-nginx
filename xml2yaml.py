import copy
from lxml import etree
import yaml
import sys

# Temporary solution

class AutoVivification(dict):
    def __getitem__(self, item):
        try:
            return dict.__getitem__(self, item)
        except KeyError:
            value = self[item] = type(self)()
            return value

def loadXml(name):
    tree = etree.parse(name)
    root = tree.getroot()
    return root, tree

def getPaths(root, tree):
    paths = []
    for child in root.getiterator():
        nodeInfo = [tree.getpath(child), child.attrib, list(child), child.text]
        if nodeInfo[-1].__str__() == 'None':
            nodeInfo[-1] = ''
        paths.append(nodeInfo)
    return paths

def getLeafs(paths):
    return [node for node in paths if node[2].__len__() == 0]

def getAttributes(paths, node):
    nodes = [n[0].split('/')[-1] for n in paths]
    attributes = [n[1] for n in paths]
    s = ''
    for key, value in attributes[nodes.index(node)].iteritems():
        s = s + '\'' + key + '=' + value + '\','
    s = s[:-1]
    if s.__len__() != 0:
        s = '[' + s + ']'
    return s

xmlFile = sys.argv[1]

root, tree = loadXml(xmlFile)

paths = getPaths(root, tree)

leafs = getLeafs(paths)

# Dictionary representation of YAML

yamlDict = AutoVivification() #{}

for i in leafs:
    nodes = i[0][1:]
    nodes = nodes.split('/')

    strCmd = "yamlDict"

    for node in nodes:
        removeInvalid = copy.copy(node)
        if removeInvalid.count('['):
            removeInvalid = removeInvalid.replace('[','-').replace(']','')
        strCmd = strCmd + '[\'' + removeInvalid + '\']'

    value = "%s" % i[3]
    exec(strCmd + ' = ' + "'" + value + "'")

    strCmd2 = "yamlDict"

    for node in nodes:
        removeInvalid = copy.copy(node)
        if removeInvalid.count('['):
            removeInvalid = removeInvalid.replace('[','-').replace(']','')
        strCmd2 = strCmd2 + '[\'' + removeInvalid + '\']'
        if getAttributes(paths, node).__len__() != 0:
            if node == nodes[-1]:
                exec(strCmd2 + ' = ' + '{}')
            temp = strCmd2 + '[\'' + 'attributes' + '\']'
            exec(temp + ' = ' + getAttributes(paths, node))


print yaml.dump(eval(yamlDict.__str__()), default_flow_style=False, allow_unicode = True, encoding = None)