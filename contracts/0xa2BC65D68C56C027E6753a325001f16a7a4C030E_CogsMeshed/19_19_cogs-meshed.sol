// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Base64.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CogsMeshed is ERC721, ERC721Royalty, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _cnt;

    uint256 private _salt = 123456;
    bytes private _secret = hex"73_65_63_72_65_74";
    address private _cogs = 0x3d5eF7C459dF62ddFa40019bed14d511391Ed318;

    // token info
    struct Tok {
        bool solved;
        string tokenURI;
    }
    mapping(uint => Tok) private _toks;

    // puzzle solutions
    struct Puz {
        uint256 tokenId;
        bytes solvedURI;
    }
    mapping(bytes32 => Puz) private _puzs;

    // event emitted on successful solution
    event Meshed(address indexed solver, uint256 indexed tokenId, string indexed ipfs);

    constructor() ERC721("CogsMeshed", "COGM") {
        _cnt.increment();  // first token is 1
        _setDefaultRoyalty(msg.sender, 333);  // default royalty of 3.33%

        // initial tokens (no puzzles solved)
        _toks[1] = Tok(false, "QmdLag9PUKLRj58y6Tunq2QPtJzcJ8VYxGc1FLU8vHwoez");
        _toks[2] = Tok(false, "QmYWokA8nbcuvMJ9V6K7gya7YveC8ieK2DA3AbCfhNrqGS");
        _toks[3] = Tok(false, "QmPXAHfqpKgWvHuie7dxnchkkhQzjkhDaMmmvD1JJRph6N");
        _toks[4] = Tok(false, "QmevfujgKw7aGFcRpVNE6zr1GntPyBKSqnWWa76TLbAXQZ");

        // begin solutions
        _puzs[0x0bddc31ac724670d09f0b7202ab1a7dc31d33d2e01d791e19d64940db19c460e] = Puz(2, hex"85cd58922b4344e5160c3f1aa267babb2517b15e9f2607232cb74fadfb3c6dc057bcac02119caa0bdfaa2f0fbe76");
        _puzs[0x1dc3f5620273ba616c473fde12dbe0358b9d232eab050fba35f54666fdd5dbf8] = Puz(4, hex"85cd6ba5514b64f50119174c9c5aaaa62945b418af023d3470832d9bea247ce273eb833770c19602b8947337b846");
        _puzs[0x28d6e98de9e3543f3c2133e5ae6acacf7cb770ff829e3e2bd1209486d88f858a] = Puz(1, hex"85cd5d9b3d514af337270c2e85598d8765509f7a8b270a026aae4bb2d438699765ac813313a09f4ebdad3134e840");
        _puzs[0x3c73c61eca4bf70abead41cf9797b01002863e251ba37158a755ce76d5baa39d] = Puz(3, hex"85cd6ccc316f50d7373608489d29998a4853957bac202a6553f410ffc62b78e557edb81874ba8455f0977d278607");
        _puzs[0x60d207da7c683ab08bb71c152252c45cea19fc28b33a03490c9fa2452ca00860] = Puz(2, hex"85cd518f3d7d53ea1f212c08ad668885511189669a301e114ca91882c40e4d9668bcc21e72a9a851edb12a2fa006");
        _puzs[0x621b459479fde742de811b9ffe24494dceaa11a3336073a4e9e621918199e332] = Puz(2, hex"85cd6d9c514e67f701220a15bc2e88825756cb79a53e3f1178b33d89fb2d749271858127449db16fb8853f0ee60a");
        _puzs[0x883d0396a173dd4687a88ac4cc9f5959936b8edfbebf4c54debbb5b0f00db7db] = Puz(2, hex"85cd5bb62f5a51e22a3c1f0ab36981f67973c84eba2532165e8638b9cf306fe26d99a7006d8cb403dcbc380b8606");
        _puzs[0x8ce22695d89224b7f210de6a3308f78daece1393c7c3f2ed453bbda9f10dbed0] = Puz(1, hex"85cd6a911a7d5bf36e20120281268df87e558b7ea10431296bf92fa5940557cd44bcc539469c976ddca82a789f5f");
        _puzs[0x8e0dc406845a473b78894814ff63eb094c942be71d847a5116772ab51b9b1d47] = Puz(1, hex"85cd5a985f6e7ff46e133e379f55869c2b17be448b26106871ba1882e51d4cd65195b4044093fd70ba88782f9705");
        _puzs[0x99cca019a728c0e508c652acfd1d1683803ec9ba8cd071f9dacd97c0aba234c8] = Puz(1, hex"85cd47983a4057c03332312eb32ab7a5647bc45aba19366951aa228cc62c60fe5ae7b34641b79008dea2283db40b");
        _puzs[0x9e05a7aa33e9a14a734f75742574e5168722d14fae2bed68a6a15f185ed7249e] = Puz(3, hex"85cd589f297c2ed50c2c4d379051b1fb2916b2448c7f096172870ba39a0154e26e8cc73f469e9352c3912c06e36b");
        _puzs[0xa4203f83f078ffb7496cd89f11affc3741ff71f5d9f2f99a0b1cd98a243c504d] = Puz(4, hex"85cd58bb5a0f5ecc08160f31856f958e6e46a8158079210457ab38adee2943d438ab80121e88a74cce937d7b9548");
        _puzs[0xa963cc4ce09a58cc4c013d07f751e14694f22d0b2b025e8ffbedf9e8c111ed10] = Puz(4, hex"85cd6db03c7f24cf2c1f1e0cdf6ca6a87a50936c853f18657bb40af9981228e26da5980213bc8349f1ad017ea463");
        _puzs[0xca7120c850226b46cea3c5c4b1ad61d5f86cdd5b6de36be41607c3bc95d25463] = Puz(3, hex"85cd6a853e522af51c2c3743ae7098a24c778a188e7141114c8a4d83f70759e343bdb434439daf74c2df0014e047");
        _puzs[0xd30606bbd488643e33f791f3cba6d49937710b2c85507d66984eae0c480e6c2f] = Puz(3, hex"85cd50bb3d7c6ecb6f63304fa659d6817014c4549a2639035e8449a6c41252934497952c76a98750fdac733d9d77");
        _puzs[0xfd7946656d7316234d4d654d4691a343dab27d6b748f436956d725aad1b712ba] = Puz(4, hex"85cd6cc72f6175d66e322d0cb02d9af92955915ad87f321a63b036bcec1d57ef3991cf1a52cff15fe8a533789359");
        // end solutions
    }
 
    function safeMint(address to) public onlyOwner {
        uint256 meshedId = _cnt.current();
        require(meshedId <= 4, "exceeded max supply");  // limit to 4
        _cnt.increment();
        _safeMint(to, meshedId);
    }

    function mesh(uint256 cogId, uint256 guessId) public payable {
        // guesser paid fee?
        require(msg.value >= 0.001 ether, "insufficient mesh fee sent");

        // guesser owns the guessed cog?
        require(msg.sender == IERC721(_cogs).ownerOf(cogId), "must own cog");

        // does cog mesh with target?
        bytes32 lookup = keccak256(abi.encodePacked(_salt, cogId, guessId));
        uint256 meshedId = _puzs[lookup].tokenId;
        require(meshedId > 0, "cogs do not mesh..guess again!");

        // ensure not yet solved?
        require(ownerOf(meshedId) == owner(), "already meshed");
        
        // solved! award token to guesser
        _transfer(owner(), msg.sender, meshedId);

        // extract and decode solution URI
        bytes memory encoded = _puzs[lookup].solvedURI;
        require(encoded.length > 0, "bad encoded solution");
        string memory decoded = string(rc4(_secret, encoded));
        require(bytes(decoded).length == 46, "bad decoded solution");

        // update tokenURI with solution
        _toks[meshedId].solved = true;
        _toks[meshedId].tokenURI = decoded;

        // emit solution
        emit Meshed(msg.sender, meshedId, string.concat("ipfs://", decoded));
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);
        string memory id = Strings.toString(tokenId);
        return string(abi.encodePacked('data:application/json;base64,', 
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name":"CogMeshed ', id, '",',
                            '"description":"Meshed Cogwheels with a splash of color. Solutions to the Cogs visual puzzle. Turn alone. Mesh together.",',
                            '"external_url":"https://mechination.xyz/cogs-meshed/', id, '",',
                            '"image":"ipfs://', _toks[tokenId].tokenURI, '",',
                            '"attributes":[{"value": "', (_toks[tokenId].solved ? "Solved" : "Hidden"), '"}]}'
                        )
                    )
                )
            )
        ));
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function rc4(bytes memory key, bytes memory input) private pure returns (bytes memory output) {
        // init state
        bytes memory S = abi.encodePacked(
            uint(0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f),
            uint(0x202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f),
            uint(0x404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f),
            uint(0x606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f),
            uint(0x808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f),
            uint(0xa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf),
            uint(0xc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf),
            uint(0xe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff)
        );

        // ksa
        uint256 i = 0;
        uint8 j = 0;
        uint256 keylen = key.length;
        unchecked {
            for (i = 0; i < 256; i++) {
                j = j + uint8(S[i]) + uint8(key[i % keylen]);
                (S[i], S[j]) = (S[j], S[i]);
            }
        }
        
        // init output
        output = new bytes(input.length);
        
        // prga
        i = 0;
        j = 0;
        unchecked {
            for (uint8 k = 0; k < input.length; k++) {
                i++;
                j += uint8(S[i]);
                (S[i], S[j]) = (S[j], S[i]);

                // xor input with keystream
                output[k] = bytes1(uint8(input[k]) ^ uint8(S[uint8(S[i]) + uint8(S[j])]));
            }
        }
        return output;
    }

    function withdraw() public nonReentrant onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "must have non-zero balance to withdraw");
        (bool success, ) = owner().call{value: bal}("");
        require(success, "failed to withdraw");
        assert(address(this).balance == 0);
    }

    // setters
    function setSalt(uint256 salt) public onlyOwner {
        _salt = salt;
    }

    function setSecret(bytes memory secret) public onlyOwner {
        _secret = secret;
    }

    function setCogs(address cogs) public onlyOwner {
        _cogs = cogs;
    }
}