// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract EthVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[34] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(19180371236082749815412587708897818390419670158646988213724647811772090677132), uint256(14261676101405252929118654635042678084041317874181734843385199439000099176406));
        vk.beta2 = Pairing.G2Point([uint256(15053087832216727031597345008905384784526286328503150102473517090408672544841), uint256(9880039693757340816426368637153772082544831745907958762279056222281963015214)], [uint256(10833276387499671602047363052437905628576810145615795323328460367667442648953), uint256(15771371962193953606658471714098477588374319556564626248002457555511389561294)]);
        vk.gamma2 = Pairing.G2Point([uint256(4100835508626462239584877924131565054342421812258774472933208524684130411585), uint256(3398980272955161939784735835270197569434200207236667564252542314235063840766)], [uint256(19261031285019620043495915140711441925020369911811330250797323807884230134840), uint256(17919604420767494567657275276801177732045508769452625243472122568473698587063)]);
        vk.delta2 = Pairing.G2Point([uint256(4833057268945428524544488207489513032661300079071765599622275532145571123515), uint256(16623277156725942990404175424392854116533139161698904444334806767818314373708)], [uint256(9531449385997855804914387216705801577255381820353171709917746971874270783951), uint256(12556936782917122160636335806257481517635264719313658998253216331010408308404)]);
        vk.IC[0] = Pairing.G1Point(uint256(1744342157045710545875250446998137017122484036776239581963246858413516628261), uint256(20097294504245045729302433061290366086794229217434966570308851357271019482346));
        vk.IC[1] = Pairing.G1Point(uint256(7276575135480447249998948300999186215503113093499012726768846160298538898203), uint256(2040026324204414555177442657609944625594840405656132229493548620699716579892));
        vk.IC[2] = Pairing.G1Point(uint256(8798638556685077227666620579682893584862388872297229894656107762628436544274), uint256(13900143069199507163829952075075174229845922258706229255246379279207589980969));
        vk.IC[3] = Pairing.G1Point(uint256(10168112529015699255258869219080574914311568381060321953267277378259685884652), uint256(19140486934684209644910158769930254044514450358842516803837183042701396114999));
        vk.IC[4] = Pairing.G1Point(uint256(16607283803432884513676857544400066645831516368795359768934897625809365459438), uint256(20272066086629726040559915954678094212748984404346266606274195215333135336303));
        vk.IC[5] = Pairing.G1Point(uint256(12070922938426658619540663575814466864525945500469293863737796810102552459287), uint256(11330220484924506518742421824050726495785275181529314569173938453937051003052));
        vk.IC[6] = Pairing.G1Point(uint256(18200338615449322306644541421135955025568099880888033429309126110550747211679), uint256(2039579805961151001562059796646276731267207624005438238646751056247279531311));
        vk.IC[7] = Pairing.G1Point(uint256(12913315478022401357786800966850409314484325460455624766236003653131876402425), uint256(15333480588607908825827568108865055326043544035254643222952673173851503137282));
        vk.IC[8] = Pairing.G1Point(uint256(4644776237033494300204468335981592684148651508374333017338455877688822756438), uint256(9950563339359170972987475583331016577543507891883214954210697181424994623424));
        vk.IC[9] = Pairing.G1Point(uint256(21321762592585623921203528751443571844332949357826958300226312414756934463318), uint256(21597200714371099168617432508609311537889297128485811760188852120874601977749));
        vk.IC[10] = Pairing.G1Point(uint256(7266292236498465397930820794167897181374633178778309284239209074623183631860), uint256(7174338552857178873898653143238842714402161781761436342987858538604756770278));
        vk.IC[11] = Pairing.G1Point(uint256(18079490907978002513385282774248724728947135796552220824006938058624021641947), uint256(7464617179668737161754133765466287235189611163934465176143443107806332582081));
        vk.IC[12] = Pairing.G1Point(uint256(6245959023130272727159801547669797378280857626096641159526345289451672737514), uint256(19583478442141155123239538171086450788489587324754387302373581530964713991447));
        vk.IC[13] = Pairing.G1Point(uint256(12883317097087827421330318701999319243507671938795167346427673331501374057870), uint256(9742348535150530738793752500456676122464155139361221377222228267731475043161));
        vk.IC[14] = Pairing.G1Point(uint256(15879155086598863675530016237069691774804303280215188039175370437630884933438), uint256(4174823219352603985761211399096260060590266565442133781379207600410438268840));
        vk.IC[15] = Pairing.G1Point(uint256(2565589978204888482540677809655973240164536757188528092980295783806423079985), uint256(17513077925402392092807565034401526595678021876232961123522340450008741707842));
        vk.IC[16] = Pairing.G1Point(uint256(2535599631329788124404410468748497335801952520492199060006037939509735160839), uint256(16801009453259935465274642511832787896738864528911343297864443568728504148089));
        vk.IC[17] = Pairing.G1Point(uint256(21721926834005028966783024001993477700435044713603643588095637143726398431589), uint256(4732984919914009194596927731794113946999419687420257679786360112199333300801));
        vk.IC[18] = Pairing.G1Point(uint256(9066099462571147214764230623507216762311535543786211062369994787577749701481), uint256(5772799521046039021247784822994579762036219505250766788465209153720264931542));
        vk.IC[19] = Pairing.G1Point(uint256(2378375813349033168839203990032001736028204860717288189855224709819262063564), uint256(18716251996974932720983853720107472593086907273749267470382377872674411546707));
        vk.IC[20] = Pairing.G1Point(uint256(9267867879848786217457519653234995377187192786596873990671453017854269960988), uint256(19061630368029917942552895718029089668111374170874107000818631284624181080402));
        vk.IC[21] = Pairing.G1Point(uint256(6040870455351035751680089509282860629339898914865471661446473592592375785110), uint256(18690000380951904164566043609499924971439094550402581052465332286480548307812));
        vk.IC[22] = Pairing.G1Point(uint256(3040053961035594217455014745198177854929152925173228408185940602080660858865), uint256(7190361898336214585676785499002648750245469477573908057602721023702579219225));
        vk.IC[23] = Pairing.G1Point(uint256(20810351846832929437424251430427037947668522176408196084525999478097517038127), uint256(9123908032221788838439870077317711874506469681899386021781764439690881653795));
        vk.IC[24] = Pairing.G1Point(uint256(3264201247277555882867618124888872240510203002828281377978112993366038780567), uint256(10803018202956637919119060171783810189196068953130750566854123246241279291421));
        vk.IC[25] = Pairing.G1Point(uint256(14344888356960606760890380922910970905250530368626884497897335241907028065200), uint256(10897988124560432199310697328323032140978622282390598416174421029455406277462));
        vk.IC[26] = Pairing.G1Point(uint256(13296510115077703407661338509710115232486450956777618437712582903291929034229), uint256(3947762838807364331209291981054036129939690812499385477345442324006578273640));
        vk.IC[27] = Pairing.G1Point(uint256(3375597872357289387277534913588267477067307842919956316808461385108735762156), uint256(10720384256917898832102650752171213260945849567726351323924989406083284474690));
        vk.IC[28] = Pairing.G1Point(uint256(16969344212911063072796145005806302786407420575656213102217953140832407651881), uint256(6445152719330454619427774103237354271085408111779992234650196294203384671424));
        vk.IC[29] = Pairing.G1Point(uint256(6485227748399988281896835960291523025613858088094693390207162973779044157925), uint256(5726154163395175937375861823102857280765281661248727268879206237337907848278));
        vk.IC[30] = Pairing.G1Point(uint256(21317317395275670682368910557126671808192902354229784427428179577706202222453), uint256(7431563658446558680198252767854248698172601344587270376468769161840836928588));
        vk.IC[31] = Pairing.G1Point(uint256(12986713009283675272624134479678883769272262533647625481661126959259452293054), uint256(9836140538426775107634198913145896516049285181935220172685710061172137492150));
        vk.IC[32] = Pairing.G1Point(uint256(156910154540262153462114267735556449178744515314943650917321954422151034951), uint256(10765539948917966676506738583001222137886434920729257286429657668547990666549));
        vk.IC[33] = Pairing.G1Point(uint256(8828590508253940278288046303720069422914742628410918289229823837025763533923), uint256(21317162196608556027107995717615300023093792178825792184542176887864488267784));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[33] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}