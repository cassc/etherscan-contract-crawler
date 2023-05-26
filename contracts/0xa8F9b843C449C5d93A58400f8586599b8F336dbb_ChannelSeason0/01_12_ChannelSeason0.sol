// SPDX-License-Identifier: MIT
//  ______   ___   ___   ________   ___   __    ___   __    ______   __
// /_____/\ /__/\ /__/\ /_______/\ /__/\ /__/\ /__/\ /__/\ /_____/\ /_/\
// \:::__\/ \::\ \\  \ \\::: _  \ \\::\_\\  \ \\::\_\\  \ \\::::_\/_\:\ \
//  \:\ \  __\::\/_\ .\ \\::(_)  \ \\:. `-\  \ \\:. `-\  \ \\:\/___/\\:\ \
//   \:\ \/_/\\:: ___::\ \\:: __  \ \\:. _    \ \\:. _    \ \\::___\/_\:\ \____
//    \:\_\ \ \\: \ \\::\ \\:.\ \  \ \\. \`-\  \ \\. \`-\  \ \\:\____/\\:\/___/\
//     \_____\/ \__\/ \::\/ \__\/\__\/ \__\/ \__\/ \__\/ \__\/ \_____\/ \_____\/
//  ______   ______   ________   ______   ______   ___   __        ______
// /_____/\ /_____/\ /_______/\ /_____/\ /_____/\ /__/\ /__/\     /_____/\
// \::::_\/_\::::_\/_\::: _  \ \\::::_\/_\:::_ \ \\::\_\\  \ \    \:::_ \ \
//  \:\/___/\\:\/___/\\::(_)  \ \\:\/___/\\:\ \ \ \\:. `-\  \ \    \:\ \ \ \
//   \_::._\:\\::___\/_\:: __  \ \\_::._\:\\:\ \ \ \\:. _    \ \    \:\ \ \ \
//     /____\:\\:\____/\\:.\ \  \ \ /____\:\\:\_\ \ \\. \`-\  \ \    \:\_\ \ \
//     \_____\/ \_____\/ \__\/\__\/ \_____\/ \_____\/ \__\/ \__\/     \_____\/

// @@@@@@@@@@@@@@@&@&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@&@@&@&@&&&@&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@&@&@@&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@&@&@@@@&&&&&@&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@&@@@@&@@&@&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@&@&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@&&&@@&&&@@&&&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@%(((((((((((((((((((((((((((((((((((/((//&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@**                                      ,#&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@////    .,,,        .,,,.       .,,,. ,,,.&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@///****////////,***//////*****//////**,..#&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@&//.,*@@@@@@%**.,,@@@@@@&**,,,&&&&&&&**,,.&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@&**.,@@@@@@@@,,.,/&@@@&&@,,,,,&&&&&&&,,.,,&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@,,.,*@@@@@@@,..,,@@@@&@@(..,,&&&&&&&%..**&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@,,. [email protected]@@@@@@*..  @@@@&@&#..  &&&&&&&&..,*&&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@/*                                     ,,&&&&&&&&&&&&@&&&&&
// @@@@@@@@@@@@@@@@%//.                                   ...&&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@%///.  ,///.       .*//,       .*//* ....,&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@***/////(/////*/////(/////./////(/////,,,&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@/,,**&@@@@@@*****(@@@@@@**,**/@@&@@@/,,**(&&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@%,,,,@@@@@@@@,.,,%@@@@@@@,..*(@@@@&@@...**&&@&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@**,,,@@@@@@@/,.,,@@@@@@@%,.,,@@@@@@@&,.*,&@@&&&&&&&&&&&&&&&
// @@@@@@@@@@@@@@@@//[email protected]@@@@@@(*,[email protected]@@@@@@&**.,@@@@@@@&**,,&&@&&&&&@&&&&&&&&&
// @@@@@@@@@@@@@@@@@((((&@@@@@@@#(((#@@@@@@@&(((#@@@@@@@&(###@&&&&@&&&&&&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@&@&@&@&@&@@@@&&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&@@&&@&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&@&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@&&@&&&&
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@&&
// code by Duncan Wilson and James Geary
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ChannelSeason0 is ERC721, Ownable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public tokenIds;
    CountersUpgradeable.Counter public devMintCount;
    uint256 constant PRICE = 330 * 10**15; // 0.33 ETH
    uint256 constant ROYALTY_PRICE = 165 * 10**14; // 5% of PRICE
    uint256 constant TOTAL_SUPPLY = 667;
    uint256 constant MAX_MINT = 10;
    uint256 constant TOTAL_DEV_MINTS = 30;
    string public baseURI;
    string public extension = ".json";
    bool public paused;
    bool public greenlistPaused;
    address payable public multisig;
    address payable public rolfes;
    address public validSigner;

    constructor(
        string memory name,
        string memory symbol,
        address payable _multisig,
        address payable _rolfeyAddy,
        address _validSigner,
        string memory _baseURI
    ) ERC721(name, symbol) {
        updateMultisig(_multisig);
        updateRolfes(_rolfeyAddy);
        updateSigner(_validSigner);
        updateURI(_baseURI);
        setPaused(true);
        setGreenlistPaused(true);
        tokenIds.increment();
    }

    function updateMultisig(address payable _multisig) public onlyOwner {
        multisig = _multisig;
    }

    function updateRolfes(address payable _rolfes) public onlyOwner {
        rolfes = _rolfes;
    }

    function updateSigner(address _validSigner) public onlyOwner {
        validSigner = _validSigner;
    }

    function updateURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function updateExtension(string memory _extension) public onlyOwner {
        extension = _extension;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setGreenlistPaused(bool _greenlistPaused) public onlyOwner {
        greenlistPaused = _greenlistPaused;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), extension)
            );
    }

    function _mintRequires(uint256 _numToMint) private view {
        require(_numToMint <= MAX_MINT);
        require(
            ((tokenIds.current() - 1) +
                _numToMint +
                (TOTAL_DEV_MINTS - devMintCount.current())) < TOTAL_SUPPLY,
            "max supply reached"
        ); // - 1 because tokenIdTracker.current starts at 1
    }

    function _payableMint(address _receiver, uint256 _numToMint) private {
        require(msg.value >= PRICE * _numToMint, "must pay mint fee for each");
        uint256 multisigFee = msg.value - ROYALTY_PRICE;
        rolfes.call{value: ROYALTY_PRICE}("");
        multisig.call{value: multisigFee}("");
        for (uint256 i = 0; i < _numToMint; i++) {
            _mint(_receiver, tokenIds.current());
            tokenIds.increment();
        }
    }

    function mint(uint256 _numToMint) public payable {
        require(paused == false, "Contract Paused");
        _mintRequires(_numToMint);
        _payableMint(msg.sender, _numToMint);
    }

    function mintTo(address _receiver, uint256 _numToMint) public payable {
        require(paused == false, "Contract Paused");
        _mintRequires(_numToMint);
        _payableMint(_receiver, _numToMint);
    }

    function teamMint(address _receiver, uint256 _numToMint) public payable onlyOwner {
        require(devMintCount.current() + _numToMint - 1 < TOTAL_DEV_MINTS);
        _mintRequires(_numToMint);
        _payableMint(_receiver, _numToMint);
        for (uint256 i = 0; i < _numToMint; i++) {
            devMintCount.increment();
        }
    }

    function recoverSigner(bytes32 _message, bytes memory _signature)
        public
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(_signature);
        return ecrecover(_message, v, r, s);
    }

    function _splitSignature(bytes memory _signature)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(_signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }
        return (v, r, s);
    }

    function getMessageHash(address _receiver, uint256 _numToMint) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_receiver, _numToMint));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function isValidData(
        address _receiver,
        uint256 _numToMint,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_receiver, _numToMint);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);        
        return recoverSigner(ethSignedMessageHash, _signature) == validSigner;
    }

    function greenlistMint(
        address receiver,
        uint256 numToMint,
        bytes memory signedMessage
    ) public payable {
        // Check that the signature is valid
        require(
            isValidData(receiver, numToMint, signedMessage),
            "Invalid signed message"
        );
        require(greenlistPaused == false, "Greenlist Minting Paused");
        _mintRequires(numToMint);
        _payableMint(receiver, numToMint);
    }
}