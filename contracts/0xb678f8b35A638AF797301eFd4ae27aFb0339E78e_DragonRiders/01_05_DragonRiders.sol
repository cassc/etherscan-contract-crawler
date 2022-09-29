// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/ERC721A.sol';


pragma solidity ^0.8.7;

contract DragonRiders is Ownable, ERC721A {
    
    string private baseurl = "ipfs://bafybeibfsyuoaw4bvalqubck4w4gelxqqlnvr5gvv3aurqxpm652x3khvy/";
    string public metaURI = "ipfs://bafybeid6pwterj3zpkwgz4zlequse3aw2paurxjy2scsq4u3oihzfetreu/meta";

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("DRAGONRIDERS", "DRGRD") {
            _safeMint(0x36d805A97A5F5De2c320E14032Fbd20B16d8d919,11);
            _safeMint(0x5A1C0D1A1f34523b6F04D681c52a636cae532501,6);
            _safeMint(0x27A9A5Fc86fc478a5D3d357D607C93F78f1f0f89,5);
            _safeMint(0x584a1d14920A49C8d19110636A2b435670CAf367,4);
            _safeMint(0x2a93E999816c9826aDe0B51AAa2d83240d8F4596,4);
            _safeMint(0xcDB75D2831cf03b053B38DF2ad20DD2E2D24e44C,3);
            _safeMint(0x86FA01f0B8c77feDd3484FC9EDe2917fb680B398,3);
            _safeMint(0x3079a30EC75471a58dF4ecF0E559007B2F014AFC,3);
            _safeMint(0xD5EB0733EC97B07aa83FB77060Aed320BADB9120,3);
            _safeMint(0x0525fa029ab0be79e4dC798B8e6F0e8Fb209D8B7,2);
            _safeMint(0x2540B93287ea012f26897f07051242cB8c7E2318,2);
            _safeMint(0x809A2d2bbd014630A4b9B440bc8566E909dae907,2);
            _safeMint(0xb190F476c9B88d2d6AB1e6E6Ca0e25ef35c0152d,2);
            _safeMint(0x6f66585B67A05c584Ec7b0c9d0130D32fD1f1E2b,1);
            _safeMint(0x72b9548ef1760912c9f75780F4AC93445a539864,1);
            _safeMint(0x35c5c4229Eea7476694c6ba5D124A420AD6769F9,1);
            _safeMint(0xF2AF75D7eE4b6FBB5439f14a2B67221e0558b249,1);
            _safeMint(0x8C7e251461FCCb363cbae2fF3FF1237D44763F58,1);
            _safeMint(0xAc77C74D7F04Fce3c4DD48Dd4D7Fb8bb1a0e6405,1);
            _safeMint(0x484188a4A74bbC095427fd0155e116C5625743b7,1);
            _safeMint(0x0Ca0175a124b7D25E5e63482Fa8e261081F47Dd1,1);
            _safeMint(0xe22b3A87f55Af822F85Ef2251A475010FB383297,1);
            _safeMint(0xE4532E96e6A45FB9b4876432c9732bd797B5F6d5,1);
            _safeMint(0xED1C1e3C8E65eD283A5d6D984136b915b37c3053,1);
            _safeMint(0x27f8f8251813b52f768dEFaCEf510a683E8AE317,1);
            _safeMint(0x6b5Af0F4Cd8dB0E744c8CEf3D6D4929D8C65D358,1);
            _safeMint(0xcE88E82Cb4d513D019E3926c7228cfE68A7ff543,1);
            _safeMint(0xaF8Fb85E1914bD78872AC5A507FfC0Feb2715622,1);
            _safeMint(0x2fC18014cd8A16bE3A3E6E1222a1cC0B5C087371,1);
            _safeMint(0x324CA564f4FfA1862afa14f18850D4E71171a03c,1);
            _safeMint(0x4f2a4Af020B1F3a3b1fE6581c3Fa276D7aa41D9e,1);
            _safeMint(0x37258723f1D735FD4B1c15fC701b574BE21c7EE1,1);
            _safeMint(0x4526E96ceDb7A4F570944c37A544B0E44b946ea4,1);
            _safeMint(0xD098F90b313f60A929B58ea2A061fF6FAaD1D6ce,1);
            _safeMint(0x56e1b883a7ee8c948d014aF899E2710B8B89dE6d,1);
            _safeMint(0x81269781E647eb0843Dc3a8fEbC55a38cE69B4eB,1);
            _safeMint(0xea79b1f6EA30a2DccB7C066Da6204fBf4131BD2C,1);
            _safeMint(0x8Dd4c965d910B7f51D92394daec2851B9b1e34d9,1);
            _safeMint(0x194968Fa95a7D6A8BCD7d68C0e20d818e624C85E,1);
            _safeMint(0x0Bbf9392d5C221E2B21cea31d91b1CfBFAe843f3,1);
            _safeMint(0xac18BAD4072a8dd2F5F6ac3dcA06d0f4BEC43e6B,1);
            _safeMint(0xAfc0d24DB87d13CB651a86dD2AfD8aB3A9A13bCf,1);
            _safeMint(0x1CAD50E69a1f6CcE08A1745e0094dBdA29c7218a,1);
            _safeMint(0x488e8B79f26b08Dc24f4528B2b8abf62E1a12912,1);
            _safeMint(0xC2e0e09aE0CB9A70fF4F458A5d458d6c12CCf49a,1);
            _safeMint(0xC85C1618EDaD32E62808376885826ff78a037Aa3,1);
            _safeMint(0x244F11463872C46376502c3eD9A58687663a175D,1);
            _safeMint(0xF3347f135334844C87e3819d4c1eB5Db7762628E,1);
            _safeMint(0x1fe7ab5cbAdBCe602F09F0AAcaf6D27F40Fb82F4,1);
            _safeMint(0xdFCba7Eae632A6eA1bE4D1cE59700b2c23db8435,1);
            _safeMint(0x1d552F9496af5d5C4CBd5b812Da2ba54AeFbA1A9,1);
            _safeMint(0xAc38F5B743b15bb7a73E16a299A11D349754FF49,1);
            _safeMint(0x9E1f1Ee211F7FC38a9c2747D76244d9cD8667Af3,1);
            _safeMint(0x8CB20D25E5D2baC7cd75aeC1c4855F1f095172B2,1);
            _safeMint(0xdC12E1964a8f9ac6BB9e029FCD17744f9e4BBC5E,1);
            _safeMint(0x00e2Ab4D09814c2A908E6a1B2238f3cd4317AbFB,1);
            _safeMint(0x6AB72bFF457dc3C74bA661e550E85a2E89F405C2,1);
            _safeMint(0xF6926D15fC0Ee0113aC4840E7d881D92Cf193a7d,1);
            _safeMint(0x647e04f1d1Cb2fF2BbCEEb85aB4d8AF5f6EeC135,1);
            _safeMint(0x0F615319D7CeeD5801faF6b13C9034DE9223a3eC,1);
            _safeMint(0x2adfc86a4E073169aC5f8C850a9e80C90383F3f8,1);
            _safeMint(0x6547e469765712C69728D603420F6B574ED05f17,1);
            _safeMint(0x5C6AE017A1811AE67F6AbA6a07009D173CCCcdB7,1);
            _safeMint(0x0ffB8c30736cb0C95F1aFa9BEe5294dBD3A0D779,1);
            _safeMint(0x6c3700467d9cA3050CB72dC05FB83Ba5ac51136D,1);
            _safeMint(0x188664a3FD1eaF75B0e87Ee558fbada4aa92C372,1);
            _safeMint(0x6E814F9DEBF9d8Bd5A74F62B115F0beE824CFE5C,1);
            _safeMint(0x44765a45B7893d153baF1218822c29619F20308d,1);
            _safeMint(0x2f44280a1A43835abb0D5c58bAC31fbd6c1B9A17,1);
            _safeMint(0x118Bec6E9600E18eE05a0B56cACFE4CA3E9B416C,1);
            _safeMint(0xAD31AA3A309F44bD84de1ae025A759199397edcb,1);
            _safeMint(0x179B3f09ecf230B42FA95Ae1B5665F43D0DF5096,1);
            _safeMint(0x428fb922793F20be0f5C6FFb5f2992eA3223cba1,1);
            _safeMint(0x2AF238C0b28aCd3620099C8a53742E9A1eF6a94b,1);


    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseurl = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId+1),".json")) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseurl;
    }

    function contractURI() public view returns (string memory) 
    {
        return metaURI;
    }
}