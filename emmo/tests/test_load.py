#!/usr/bin/env python3
import sys
import os

# Add emmo to sys path
thisdir = os.path.abspath(os.path.dirname(__file__))
sys.path.insert(1, os.path.abspath(os.path.join(thisdir, '..', '..')))
from emmo import get_ontology, World  # noqa: E402, F401

import owlready2  # noqa: E402, F401


# Load latest stable EMMO
emmo = get_ontology('emmo')
emmo.load()
nclasses = len(set(emmo.get_entities(
    imported=1, individuals=0, object_properties=0,
    data_properties=0, annotation_properties=0)))


# Load emmo-inferred
world = World()
inferred = world.get_ontology()
inferred.load()
assert nclasses == len(list(inferred.classes()))


#----------------------------------------------------------
# Tests requirering local version of EMMO
#----------------------------------------------------------
emmodir = os.path.join(thisdir, '..', '..', '..', 'EMMO')
owlready2.set_log_level(0)


# Load local EMMO
if os.path.exists(os.path.join(emmodir, 'emmo.owl')):
    world2 = World()
    local = world2.get_ontology(os.path.join(emmodir, 'emmo.owl'))
    local.load(use_catalog=True)
    assert nclasses == len(list(local.classes()))


# Load EMMO from base iri inferred from catalog file
if os.path.exists(os.path.join(emmodir, 'catalog-v001.xml')):
    world3 = World()
    onto = world3.get_ontology(os.path.join(emmodir, 'catalog_v001.xml'))
    onto.load(use_catalog=True)
    assert nclasses == len(list(onto.classes()))
