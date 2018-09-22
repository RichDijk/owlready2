# -*- coding: utf-8 -*-
# Owlready2
# Copyright (C) 2013-2018 Jean-Baptiste LAMY
# LIMICS (Laboratoire d'informatique médicale et d'ingénierie des connaissances en santé), UMR_S 1142
# University Paris 13, Sorbonne paris-Cité, Bobigny, France

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys, xml.parsers.expat

from owlready2.base import OwlReadyOntologyParsingError

cdef str rdf_type = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"

cdef dict types = {
  "http://www.w3.org/2002/07/owl#Class"              : "http://www.w3.org/2002/07/owl#Class",
  "http://www.w3.org/2002/07/owl#NamedIndividual"    : "http://www.w3.org/2002/07/owl#NamedIndividual",
  "http://www.w3.org/2002/07/owl#ObjectProperty"     : "http://www.w3.org/2002/07/owl#ObjectProperty",
  "http://www.w3.org/2002/07/owl#DataProperty"       : "http://www.w3.org/2002/07/owl#DatatypeProperty",
  "http://www.w3.org/2002/07/owl#AnnotationProperty" : "http://www.w3.org/2002/07/owl#AnnotationProperty",
}

cdef dict prop_types = {
  "http://www.w3.org/2002/07/owl#FunctionalObjectProperty"        : "http://www.w3.org/2002/07/owl#FunctionalProperty",
  "http://www.w3.org/2002/07/owl#FunctionalDataProperty"          : "http://www.w3.org/2002/07/owl#FunctionalProperty",
  "http://www.w3.org/2002/07/owl#InverseFunctionalObjectProperty" : "http://www.w3.org/2002/07/owl#InverseFunctionalProperty",
  "http://www.w3.org/2002/07/owl#InverseFunctionalDataProperty"   : "http://www.w3.org/2002/07/owl#InverseFunctionalProperty",
  "http://www.w3.org/2002/07/owl#IrreflexiveObjectProperty"       : "http://www.w3.org/2002/07/owl#IrreflexiveProperty",
  "http://www.w3.org/2002/07/owl#IrreflexiveDataProperty"         : "http://www.w3.org/2002/07/owl#IrreflexiveProperty",
  "http://www.w3.org/2002/07/owl#ReflexiveObjectProperty"         : "http://www.w3.org/2002/07/owl#ReflexiveProperty",
  "http://www.w3.org/2002/07/owl#ReflexiveDataProperty"           : "http://www.w3.org/2002/07/owl#ReflexiveProperty",
  "http://www.w3.org/2002/07/owl#SymmetricObjectProperty"         : "http://www.w3.org/2002/07/owl#SymmetricProperty",
  "http://www.w3.org/2002/07/owl#SymmetricDataProperty"           : "http://www.w3.org/2002/07/owl#SymmetricProperty",
  "http://www.w3.org/2002/07/owl#AsymmetricObjectProperty"        : "http://www.w3.org/2002/07/owl#AsymmetricProperty",
  "http://www.w3.org/2002/07/owl#AsymmetricDataProperty"          : "http://www.w3.org/2002/07/owl#AsymmetricProperty",
  "http://www.w3.org/2002/07/owl#TransitiveObjectProperty"        : "http://www.w3.org/2002/07/owl#TransitiveProperty",
  "http://www.w3.org/2002/07/owl#TransitiveDataProperty"          : "http://www.w3.org/2002/07/owl#TransitiveProperty",
}

cdef dict sub_ofs = {
  "http://www.w3.org/2002/07/owl#SubClassOf"              : "http://www.w3.org/2000/01/rdf-schema#subClassOf",
  "http://www.w3.org/2002/07/owl#SubPropertyOf"           : "http://www.w3.org/2000/01/rdf-schema#subPropertyOf",
  "http://www.w3.org/2002/07/owl#SubObjectPropertyOf"     : "http://www.w3.org/2000/01/rdf-schema#subPropertyOf",
  "http://www.w3.org/2002/07/owl#SubDataPropertyOf"       : "http://www.w3.org/2000/01/rdf-schema#subPropertyOf",
  "http://www.w3.org/2002/07/owl#SubAnnotationPropertyOf" : "http://www.w3.org/2000/01/rdf-schema#subPropertyOf",
  }

cdef dict equivs = {
  "http://www.w3.org/2002/07/owl#EquivalentClasses" : "http://www.w3.org/2002/07/owl#equivalentClass",
  "http://www.w3.org/2002/07/owl#EquivalentProperties" : "http://www.w3.org/2002/07/owl#equivalentProperty",
  "http://www.w3.org/2002/07/owl#EquivalentObjectProperties" : "http://www.w3.org/2002/07/owl#equivalentProperty",
  "http://www.w3.org/2002/07/owl#EquivalentDataProperties" : "http://www.w3.org/2002/07/owl#equivalentProperty",
  "http://www.w3.org/2002/07/owl#EquivalentAnnotationProperties" : "http://www.w3.org/2002/07/owl#equivalentProperty",
  "http://www.w3.org/2002/07/owl#SameIndividual" : "http://www.w3.org/2002/07/owl#sameAs",
  }

cdef dict restrs = {
  "http://www.w3.org/2002/07/owl#ObjectSomeValuesFrom" : "http://www.w3.org/2002/07/owl#someValuesFrom",
  "http://www.w3.org/2002/07/owl#ObjectAllValuesFrom"  : "http://www.w3.org/2002/07/owl#allValuesFrom",
  "http://www.w3.org/2002/07/owl#DataSomeValuesFrom"   : "http://www.w3.org/2002/07/owl#someValuesFrom",
  "http://www.w3.org/2002/07/owl#DataAllValuesFrom"    : "http://www.w3.org/2002/07/owl#allValuesFrom",
  "http://www.w3.org/2002/07/owl#ObjectHasValue"       : "http://www.w3.org/2002/07/owl#hasValue",
  "http://www.w3.org/2002/07/owl#DataHasValue"         : "http://www.w3.org/2002/07/owl#hasValue",
  }

cdef dict qual_card_restrs = {
  "http://www.w3.org/2002/07/owl#ObjectExactCardinality" : "http://www.w3.org/2002/07/owl#qualifiedCardinality",
  "http://www.w3.org/2002/07/owl#ObjectMinCardinality"   : "http://www.w3.org/2002/07/owl#minQualifiedCardinality",
  "http://www.w3.org/2002/07/owl#ObjectMaxCardinality"   : "http://www.w3.org/2002/07/owl#maxQualifiedCardinality",
  "http://www.w3.org/2002/07/owl#DataExactCardinality"   : "http://www.w3.org/2002/07/owl#qualifiedCardinality",
  "http://www.w3.org/2002/07/owl#DataMinCardinality"     : "http://www.w3.org/2002/07/owl#minQualifiedCardinality",
  "http://www.w3.org/2002/07/owl#DataMaxCardinality"     : "http://www.w3.org/2002/07/owl#maxQualifiedCardinality",
  }

cdef dict card_restrs = {
  "http://www.w3.org/2002/07/owl#ObjectExactCardinality" : "http://www.w3.org/2002/07/owl#cardinality",
  "http://www.w3.org/2002/07/owl#ObjectMinCardinality"   : "http://www.w3.org/2002/07/owl#minCardinality",
  "http://www.w3.org/2002/07/owl#ObjectMaxCardinality"   : "http://www.w3.org/2002/07/owl#maxCardinality",
  "http://www.w3.org/2002/07/owl#DataExactCardinality"   : "http://www.w3.org/2002/07/owl#cardinality",
  "http://www.w3.org/2002/07/owl#DataMinCardinality"     : "http://www.w3.org/2002/07/owl#minCardinality",
  "http://www.w3.org/2002/07/owl#DataMaxCardinality"     : "http://www.w3.org/2002/07/owl#maxCardinality",
  }

cdef dict disjoints = {
  "http://www.w3.org/2002/07/owl#DisjointClasses"              : ("http://www.w3.org/2002/07/owl#AllDisjointClasses"   , "http://www.w3.org/2002/07/owl#disjointWith", "http://www.w3.org/2002/07/owl#members"),
  "http://www.w3.org/2002/07/owl#DisjointObjectProperties"     : ("http://www.w3.org/2002/07/owl#AllDisjointProperties", "http://www.w3.org/2002/07/owl#propertyDisjointWith", "http://www.w3.org/2002/07/owl#members"),
  "http://www.w3.org/2002/07/owl#DisjointDataProperties"       : ("http://www.w3.org/2002/07/owl#AllDisjointProperties", "http://www.w3.org/2002/07/owl#propertyDisjointWith", "http://www.w3.org/2002/07/owl#members"),
  "http://www.w3.org/2002/07/owl#DisjointAnnotationProperties" : ("http://www.w3.org/2002/07/owl#AllDisjointProperties", "http://www.w3.org/2002/07/owl#propertyDisjointWith", "http://www.w3.org/2002/07/owl#members"),
  "http://www.w3.org/2002/07/owl#DifferentIndividuals"         : ("http://www.w3.org/2002/07/owl#AllDifferent"         , None, "http://www.w3.org/2002/07/owl#distinctMembers"),
}



def parse_owlxml(object f, object on_prepare_triple = None, object new_blank = None, object new_literal = None):
  cdef object parser = xml.parsers.expat.ParserCreate(None, "")
  try:
    parser.buffer_text          = True
    parser.specified_attributes = True
  except: pass
  
  cdef str ontology_iri           = ""
  cdef list objs                  = []
  cdef list annots                = []
  cdef dict prefixes              = {}
  cdef str current_content        = ""
  cdef dict current_attrs         = None
  cdef int current_blank          = 0
  cdef bint in_declaration        = False
  cdef bint in_prop_chain         = False
  cdef bint before_declaration    = True
  cdef str last_cardinality       = "0"
  cdef int nb_triple              = 0
  
  
  if not on_prepare_triple:
    def on_prepare_triple(str s, str p, str o):
      nonlocal nb_triple
      nb_triple += 1
      if not s.startswith("_"): s = "<%s>" % s
      if not (o.startswith("_") or o.startswith('"')): o = "<%s>" % o
      print("%s %s %s ." % (s,"<%s>" % p,o))
      
  if not new_blank:
    def new_blank():
      nonlocal current_blank
      current_blank += 1
      return "_:%s" % current_blank
    
  if not new_literal:
    def new_literal(str value, dict attrs):
      value = value.replace('"', '\\"').replace("\n", "\\n")
      cdef str lang = attrs.get("http://www.w3.org/XML/1998/namespacelang")
      if lang: return '"%s"@%s' % (value, lang)
      cdef str datatype = attrs.get("datatypeIRI")
      if datatype: return '"%s"^^<%s>' % (value, datatype)
      return '"%s"' % (value)
    
  def new_list(list l):
    cdef str bn
    cdef str bn0
    cdef str bn_next
    cdef int i
    
    bn = bn0 = new_blank()
    
    if l:
      for i in range(len(l) - 1):
        on_prepare_triple(bn, "http://www.w3.org/1999/02/22-rdf-syntax-ns#first", l[i])
        bn_next = new_blank()
        on_prepare_triple(bn, "http://www.w3.org/1999/02/22-rdf-syntax-ns#rest", bn_next)
        bn = bn_next
      on_prepare_triple(bn, "http://www.w3.org/1999/02/22-rdf-syntax-ns#first", l[-1])
      on_prepare_triple(bn, "http://www.w3.org/1999/02/22-rdf-syntax-ns#rest", "http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
      
    else:
      on_prepare_triple(bn, "http://www.w3.org/1999/02/22-rdf-syntax-ns#first", "http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
      on_prepare_triple(bn, "http://www.w3.org/1999/02/22-rdf-syntax-ns#rest",  "http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
      
    return bn0
  
  
  
  def unabbreviate_IRI(str abbreviated_iri):
    cdef str prefix, name
    prefix, name = abbreviated_iri.split(":", 1)
    return prefixes[prefix] + name
  
  def get_IRI(dict attrs):
    nonlocal ontology_iri
    cdef str iri
    if "IRI" in attrs:
      iri = attrs["IRI"]
      if not iri: return ontology_iri
      if   iri.startswith("#") or iri.startswith("/"): iri = ontology_iri + iri
      return iri
    return unabbreviate_IRI(attrs["abbreviatedIRI"])
  
  def startElement(str tag, dict attrs):
    nonlocal current_content, current_attrs, in_declaration, before_declaration, last_cardinality, in_prop_chain, ontology_iri
    current_content = ""
    if   (tag == "http://www.w3.org/2002/07/owl#Prefix"):
      prefixes[attrs["name"]] = attrs["IRI"]
    
    elif (tag == "http://www.w3.org/2002/07/owl#Declaration"):
      in_declaration     = True
      before_declaration = False
      
    elif (tag in types):
      iri = get_IRI(attrs)
      if in_declaration: on_prepare_triple(iri, rdf_type, types[tag])
      objs.append(iri)
      
    elif (tag == "http://www.w3.org/2002/07/owl#Datatype"):           objs.append(get_IRI(attrs))
    
    elif (tag == "http://www.w3.org/2002/07/owl#Literal"):            current_attrs = attrs
    
    elif((tag == "http://www.w3.org/2002/07/owl#ObjectIntersectionOf") or (tag == "http://www.w3.org/2002/07/owl#ObjectUnionOf") or (tag == "http://www.w3.org/2002/07/owl#ObjectOneOf") or
         (tag == "http://www.w3.org/2002/07/owl#DataIntersectionOf") or (tag == "http://www.w3.org/2002/07/owl#DataUnionOf") or
         (tag == "http://www.w3.org/2002/07/owl#DisjointClasses") or (tag == "http://www.w3.org/2002/07/owl#DisjointObjectProperties") or (tag == "http://www.w3.org/2002/07/owl#DisjointDataProperties") or (tag == "http://www.w3.org/2002/07/owl#DifferentIndividuals")):
      objs.append("(")
      
    elif((tag == "http://www.w3.org/2002/07/owl#ObjectExactCardinality") or (tag == "http://www.w3.org/2002/07/owl#ObjectMinCardinality") or (tag == "http://www.w3.org/2002/07/owl#ObjectMaxCardinality") or
         (tag == "http://www.w3.org/2002/07/owl#DataExactCardinality"  ) or (tag == "http://www.w3.org/2002/07/owl#DataMinCardinality"  ) or (tag == "http://www.w3.org/2002/07/owl#DataMaxCardinality"  )):
      objs.append("(")
      last_cardinality = attrs["cardinality"]
      
    elif (tag == "http://www.w3.org/2002/07/owl#AnonymousIndividual"): objs.append(new_blank())
    
    elif (tag == "http://www.w3.org/2002/07/owl#SubObjectPropertyOf"): in_prop_chain = False
    
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectInverseOf") or (tag == "http://www.w3.org/2002/07/owl#DataInverseOf") or (tag == "http://www.w3.org/2002/07/owl#inverseOf"): objs.append(new_blank())
    
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectPropertyChain"): objs.append("(")
    
    elif (tag == "http://www.w3.org/2002/07/owl#DatatypeRestriction"): objs.append("(")
    
    elif (tag == "http://www.w3.org/2002/07/owl#FacetRestriction"): objs.append(attrs["facet"])
    
    elif (tag == "http://www.w3.org/2002/07/owl#Ontology"):
      ontology_iri = attrs["ontologyIRI"]
      on_prepare_triple(ontology_iri, rdf_type, "http://www.w3.org/2002/07/owl#Ontology")
      version_iri = attrs.get("versionIRI")
      if version_iri:
        on_prepare_triple(ontology_iri, "http://www.w3.org/2002/07/owl#versionIRI", version_iri)
      
    elif (tag == "RDF") or (tag == "rdf:RDF"): raise ValueError("Not an OWL/XML file! (It seems to be an OWL/RDF file)")
    
    
  def endElement(str tag):
    nonlocal in_declaration, objs, in_prop_chain

    if   (tag == "http://www.w3.org/2002/07/owl#Declaration"):
      in_declaration = False
      objs = [] # Purge stack
      
    elif (tag == "http://www.w3.org/2002/07/owl#Literal"):
      objs.append(new_literal(current_content, current_attrs))
      
    elif (tag == "http://www.w3.org/2002/07/owl#SubClassOf") or (tag == "http://www.w3.org/2002/07/owl#SubObjectPropertyOf") or (tag == "http://www.w3.org/2002/07/owl#SubDataPropertyOf") or (tag == "http://www.w3.org/2002/07/owl#SubAnnotationPropertyOf"):
      parent = objs.pop()
      child  = objs.pop()
      if (tag == "http://www.w3.org/2002/07/owl#SubObjectPropertyOf") and in_prop_chain:
        relation = "http://www.w3.org/2002/07/owl#propertyChainAxiom"
        parent, child = child, parent
      else:
        relation = sub_ofs[tag]
      on_prepare_triple(child, relation, parent)
      if annots: purge_annotations((child, relation, parent))
      
    elif (tag == "http://www.w3.org/2002/07/owl#ClassAssertion"):
      child  = objs.pop() # Order is reversed compared to SubClassOf!
      parent = objs.pop()
      on_prepare_triple(child, rdf_type, parent)
      if annots: purge_annotations((child, rdf_type, parent))
      
    elif (tag == "http://www.w3.org/2002/07/owl#EquivalentClasses") or (tag == "http://www.w3.org/2002/07/owl#EquivalentObjectProperties") or (tag == "http://www.w3.org/2002/07/owl#EquivalentDataProperties"):
      o1 = objs.pop()
      o2 = objs.pop()
      if o1.startswith("_"): o1, o2 = o2, o1 # Swap in order to have blank node at third position -- rapper seems to do that
      on_prepare_triple(o1, equivs[tag], o2)
      if annots: purge_annotations((o1, equivs[tag], o2))
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectPropertyDomain") or (tag == "http://www.w3.org/2002/07/owl#DataPropertyDomain") or (tag == "http://www.w3.org/2002/07/owl#AnnotationPropertyDomain"):
      val = objs.pop(); obj = objs.pop();
      on_prepare_triple(obj, "http://www.w3.org/2000/01/rdf-schema#domain", val)
      if annots: purge_annotations((obj, "http://www.w3.org/2000/01/rdf-schema#domain", val))
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectPropertyRange") or (tag == "http://www.w3.org/2002/07/owl#DataPropertyRange") or (tag == "http://www.w3.org/2002/07/owl#AnnotationPropertyRange"):
      val = objs.pop(); obj = objs.pop();
      on_prepare_triple(obj, "http://www.w3.org/2000/01/rdf-schema#range", val)
      if annots: purge_annotations((obj, "http://www.w3.org/2000/01/rdf-schema#range", val))
      
    elif (tag in prop_types):
      obj = objs.pop()
      on_prepare_triple(obj, rdf_type, prop_types[tag])
      
    elif (tag == "http://www.w3.org/2002/07/owl#InverseObjectProperties") or (tag == "http://www.w3.org/2002/07/owl#InverseDataProperties"):
      a, b = objs.pop(), objs.pop()
      on_prepare_triple(b, "http://www.w3.org/2002/07/owl#inverseOf", a)
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectPropertyChain"):
      start    = _rindex(objs)
      list_iri = new_list(objs[start + 1 : ])
      in_prop_chain = True
      objs[start :] = [list_iri]
      
    elif (tag in disjoints):
      start    = _rindex(objs)
      list_obj = objs[start + 1 : ]
      tag, rel, member = disjoints[tag]
      if rel and (len(list_obj) == 2):
        on_prepare_triple(list_obj[0], rel, list_obj[1])
        if annots: purge_annotations((list_obj[0], rel, list_obj[1]))
        
      else:
        list_iri = new_list(list_obj)
        iri = new_blank()
        on_prepare_triple(iri, rdf_type, tag)
        on_prepare_triple(iri, member, list_iri)
        if annots: purge_annotations((iri, rdf_type, tag))
        
      del objs[start :]
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectPropertyAssertion") or (tag == "http://www.w3.org/2002/07/owl#DataPropertyAssertion"):
      p,s,o = objs[-3 :]
      on_prepare_triple(s, p, o)
      if annots: purge_annotations((s,p,o))
      del objs[-3 :]
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectComplementOf") or (tag == "http://www.w3.org/2002/07/owl#DataComplementOf"):
      iri = new_blank()
      on_prepare_triple(iri, rdf_type, "http://www.w3.org/2002/07/owl#Class")
      on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#complementOf", objs[-1])
      objs[-1] = iri
    
    elif (tag in restrs):
      iri = new_blank()
      on_prepare_triple(iri, rdf_type, "http://www.w3.org/2002/07/owl#Restriction")
      on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#onProperty", objs.pop(-2))
      on_prepare_triple(iri, restrs[tag], objs[-1])
      objs[-1] = iri
      
    elif (tag in card_restrs):
      iri = new_blank()
      on_prepare_triple(iri, rdf_type, "http://www.w3.org/2002/07/owl#Restriction")
      start = _rindex(objs)
      values = objs[start + 1 : ]
      del objs[start :]
      
      if len(values) == 2: # Qualified
        tag = qual_card_restrs[tag]
        on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#onProperty", values[-2])
        if objs[-1].startswith("http://www.w3.org/2001/XMLSchema"):
          on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#onDataRange", values[-1])
        else:
          on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#onClass", values[-1])
      else: # Non qualified
        tag = card_restrs[tag]
        on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#onProperty", values[-1])
      on_prepare_triple(iri, tag, new_literal(last_cardinality, {"datatypeIRI" : "http://www.w3.org/2001/XMLSchema#nonNegativeInteger"}))
      objs.append(iri)
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectOneOf"):
      start    = _rindex(objs)
      list_iri = new_list(objs[start + 1 : ])
      iri      = new_blank()
      on_prepare_triple(iri, rdf_type, "http://www.w3.org/2002/07/owl#Class")
      on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#oneOf", list_iri)
      objs[start :] = [iri]
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectIntersectionOf") or (tag == "http://www.w3.org/2002/07/owl#ObjectUnionOf") or (tag == "http://www.w3.org/2002/07/owl#DataIntersectionOf") or (tag == "http://www.w3.org/2002/07/owl#DataUnionOf"):
      start    = _rindex(objs)
      list_iri = new_list(objs[start + 1 : ])
      iri      = new_blank()
      if objs[start + 1 : ][0].startswith("http://www.w3.org/2001/XMLSchema"):
        on_prepare_triple(iri, rdf_type, "http://www.w3.org/2000/01/rdf-schema#Datatype")
      else:
        on_prepare_triple(iri, rdf_type, "http://www.w3.org/2002/07/owl#Class")
      if (tag == "http://www.w3.org/2002/07/owl#ObjectIntersectionOf") or (tag == "http://www.w3.org/2002/07/owl#DataIntersectionOf"):
        on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#intersectionOf", list_iri)
      else:
        on_prepare_triple(iri, "http://www.w3.org/2002/07/owl#unionOf", list_iri)
      objs[start :] = [iri]
      
    elif (tag == "http://www.w3.org/2002/07/owl#Import"):
      on_prepare_triple(ontology_iri, "http://www.w3.org/2002/07/owl#imports", current_content)
      
    elif (tag == "http://www.w3.org/2002/07/owl#IRI"):
      iri = current_content
      if not iri: iri = ontology_iri
      else:
        if iri.startswith("#") or iri.startswith("/"): iri = ontology_iri + iri
      objs.append(iri)
      
    elif (tag == "http://www.w3.org/2002/07/owl#AbbreviatedIRI"):
      iri = unabbreviate_IRI(current_content)
      objs.append(iri)
      
    elif (tag == "http://www.w3.org/2002/07/owl#AnnotationAssertion"):
      on_prepare_triple(objs[-2], objs[-3], objs[-1])
      if annots: purge_annotations((objs[-2], objs[-3], objs[-1]))
      
    elif (tag == "http://www.w3.org/2002/07/owl#Annotation"):
      if before_declaration: # On ontology
        on_prepare_triple(ontology_iri, objs[-2], objs[-1])
      else:
        annots.append((objs[-2], objs[-1]))
      del objs[-2:]
      
    elif (tag == "http://www.w3.org/2002/07/owl#DatatypeRestriction"):
      start               = _rindex(objs)
      datatype, *list_bns = objs[start + 1 : ]
      list_bns            = new_list(list_bns)
      bn                  = new_blank()
      objs[start :]  = [bn]
      on_prepare_triple(bn, rdf_type, "http://www.w3.org/2000/01/rdf-schema#Datatype")
      on_prepare_triple(bn, "http://www.w3.org/2002/07/owl#onDatatype", datatype)
      on_prepare_triple(bn, "http://www.w3.org/2002/07/owl#withRestrictions", list_bns)
      
    elif (tag == "http://www.w3.org/2002/07/owl#FacetRestriction"):
      facet, literal = objs[-2:]
      bn = new_blank()
      on_prepare_triple(bn, facet, literal)
      objs[-2:] = [bn]
      
    elif (tag == "http://www.w3.org/2002/07/owl#ObjectInverseOf") or (tag == "http://www.w3.org/2002/07/owl#DataInverseOf") or (tag == "http://www.w3.org/2002/07/owl#inverseOf"):
      bn, prop = objs[-2:]
      on_prepare_triple(bn, "http://www.w3.org/2002/07/owl#inverseOf", prop)
      
      objs[-2:] = [bn]
    
      
  def characters(str content):
    nonlocal current_content
    current_content += content
    
  def purge_annotations(on_iri):
    nonlocal annots
    cdef str s,p,o, prop_iri, value
    if isinstance(on_iri, tuple):
      s,p,o  = on_iri
      on_iri = new_blank()
      on_prepare_triple(on_iri, rdf_type, "http://www.w3.org/2002/07/owl#Axiom")
      on_prepare_triple(on_iri, "http://www.w3.org/2002/07/owl#annotatedSource", s)
      on_prepare_triple(on_iri, "http://www.w3.org/2002/07/owl#annotatedProperty", p)
      on_prepare_triple(on_iri, "http://www.w3.org/2002/07/owl#annotatedTarget", o)
      
    for prop_iri, value in annots: on_prepare_triple(on_iri, prop_iri, value)
    annots = []


  parser.StartElementHandler       = startElement
  parser.EndElementHandler         = endElement
  parser.CharacterDataHandler      = characters

  try:
    if isinstance(f, str):
      f = open(f, "rb")
      parser.ParseFile(f)
      f.close()
    else:
      parser.ParseFile(f)
      
  except Exception as e:
    raise OwlReadyOntologyParsingError("OWL/XML parsing error in file %s, line %s, column %s." % (getattr(f, "name", "???"), parser.CurrentLineNumber, parser.CurrentColumnNumber)) from e
  
  return nb_triple



    
cdef int _rindex(list l):
  i = len(l) - 1
  while l[i] != "(": i -= 1
  return i

    