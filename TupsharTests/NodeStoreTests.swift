//
//  NodeStoreTests.swift
//  TupsharTests
//
//  Created by Chaitanya Kanchan on 17/02/2019.
//  Copyright © 2019 Chaitanya Kanchan. All rights reserved.
//

import XCTest
import CDKSwiftOracc

@testable import Tupshar

class NodeStoreTests: XCTestCase {

    var nodeStore: NodeStore = NodeStore(textID: "U000000", cuneifier: {return $0})
    
    func testNodeStore() -> NodeStore {
        let testID: TextID = "U000000"
        let cuneifier: (String) -> String = {return $0}
        let testLemma = {(normalisation, transliteration, translation, line, position) in
            return OraccCDLNode(normalisation: normalisation, transliteration: transliteration, translation: translation, cuneifier: cuneifier, textID: testID, line: line, position: position)
        }
        
        let nodes: [Int: [OraccCDLNode]] = [
            1: [OraccCDLNode(lineBreakLabel: "1"),
                testLemma("ištēn", "iš-te-en", "first", 1, 1),
                testLemma("šaniš", "ša-ni-iš", "second", 1, 2),
                testLemma("šalāš", "ša-la-aš", "third", 1, 3)],
            
            2: [OraccCDLNode(lineBreakLabel: "2"),
                testLemma("alpu", "GUD", "ox-alpha", 2, 1),
                testLemma("bētu", "É", "house-beta", 2, 2),
                testLemma("gammalu", "GAM.MAL", "camel-gamma", 2, 3),
                testLemma("dāltu", "GIŠ.IG", "door-delta", 2, 4)],
            
            3: [OraccCDLNode(lineBreakLabel: "3"),
                testLemma("Šarru-kēnu", "LUGAL.GI.NA", "Sargon", 3, 1),
                testLemma("Sin-aḫḫē-eriba", "DINGIR.30.ŠEŠ.MEŠ-iri4-ba", "Sennacherib", 3, 2),
                testLemma("Aššur-aḫi-iddina", "DINGIR.AN.ŠÀR-ŠEŠ-SUM.NA", "Esarhaddon", 3, 3),
                testLemma("Aššur-bani-apli", "DINGIR.AN.ŠÀR-DÙ-DUMU.UŠ", "Aššurbanipal", 3, 4)]
        ]
        
        return NodeStore(textID: testID, cuneifier: cuneifier, nodes: nodes)
    }
    
    override func setUp() {
        nodeStore = NodeStore(textID: "U000000", cuneifier: {return $0})
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAddLemma() {
        let normalisation = "first"
        let transliteration = "fi-ir-st"
        let translation = "First Lemma"
        
        nodeStore.appendLemma(normalisation: normalisation, transliteration: transliteration, translation: translation)
        guard let line = nodeStore.nodes[1] else {
            XCTFail("Adding a lemma to an empty nodeStore should result in a new line with line number `1`")
            fatalError("Shouldn't reach this point")
        }
        
        XCTAssertTrue(line.count == 2, "Adding a single lemma to a new Line should result in a count of two")

        let discontinuityNode = line.first
        XCTAssertNotNil(discontinuityNode, "Adding a single lemma to a new Line should result in a Discontinuity automatically being prepended to a new line")
        guard case let OraccCDLNode.d(discontinuity)? = discontinuityNode else {
            XCTFail("DiscontinuityNode should be a case of `OraccCDLNode.d`")
            fatalError("Shouldn't reach this point")
        }
        
        XCTAssertTrue(discontinuity.type == .linestart, "Discontinuity type should be of `.linestart`")
        XCTAssertEqual(discontinuity.label, "1", "Discontinuity label should be automatic line numbering beginning at '1' matching the line entry")
        
        let lemmaNode = line.last
        XCTAssertNotNil(lemmaNode, "Adding a single lemma to a new Line should result in that lemma being the last entry on that line")
        guard case let OraccCDLNode.l(lemma)? = lemmaNode else {
            XCTFail("LemmaNode should be a case of `OraccCDLNode.l`")
            fatalError("Shouldn't reach this point")
        }
        
        XCTAssertEqual(lemma.reference.base, nodeStore.textID, "Lemma reference textID should match that of nodestore")
        XCTAssertEqual(lemma.reference.path, ["1","1"], "Lemma path should be first line, first lemma")
        XCTAssertEqual(lemma.fragment, transliteration, "Lemma transliteration should match that supplied in `nodeStore.addLemma`")
        XCTAssertEqual(lemma.wordForm.normalisation, normalisation, "Lemma normalisation should match that supplied in `nodeSTore.addLemma`")
        XCTAssertEqual(lemma.wordForm.translation.guideWord, translation, "Lemma translation should match that supplied in `nodeSTore.addLemma`")
        
    }
    
    func testDeleteLemma() {
        nodeStore = testNodeStore()

        let gamma = nodeStore.nodes[2]?[3]
        XCTAssertNotNil(gamma, "Should have retrieved a node from line 2, fourth index")
        XCTAssertEqual(gamma?.reference, "U000000.2.3", "Reference should equal testID, line 2, third position")
        
        nodeStore.deleteNode(lineNumber: 2, position: 3)
        
        let secondLine = nodeStore.nodes[2]
        XCTAssertNotNil(secondLine, "Line 2 should exist")
        
        XCTAssertEqual(secondLine?[1].normalised(), "alpu ", "Second line, first lemma normalisation should be 'alpu' with trailing space delimiter")
        XCTAssertEqual(secondLine?[2].normalised(), "bētu ", "Second line, second lemma normalisation should be 'bētu with trailing space delimiter")
        XCTAssertEqual(secondLine?[3].normalised(), "dāltu ", "Second line, third lemma normalisation should now be 'dāltu' with trailing space delimiter")
        XCTAssertEqual(secondLine?[3].reference, "U000000.2.3", "Second line, third lemma normalisation should be decremented from `U000000.2.4` to `U000000.2.3`")
    }

    func testModifyLemmaInPlace() {
        nodeStore = testNodeStore()
        
    }
    
}
