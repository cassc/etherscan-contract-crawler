// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EOSDreamClub is ERC721A, Ownable {
    using ECDSA for bytes32;

    string private baseTokenURI;
    address public signerAddr;

    uint256 public constant MAX_SUPPLY = 10000;

    constructor(string memory _tokenURI, address _signerAddr)
        ERC721A("EOSDreamClub", "EOSDREAMCLUB")
    {
        _setTokenURI(_tokenURI);
        _setSigner(_signerAddr);
    }

    modifier canMint(uint256 quantity) {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _isSignedBySigner(
        bytes32 hash,
        bytes memory _signature,
        address signer
    ) internal pure returns (bool) {
        return signer == hash.recover(_signature);
    }

    function _setSigner(address _signerAddr) internal {
        signerAddr = _signerAddr;
    }

    function _setTokenURI(string memory _tokenURI) internal {
        baseTokenURI = _tokenURI;
    }

    function setSigner(address _signerAddr) public onlyOwner {
        _setSigner(_signerAddr);
    }

    function removeSigner() public onlyOwner {
        _setSigner(address(0));
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenURI);
    }

    function mintWithSignerSigned(
        bytes memory _signature,
        uint256 start,
        uint256 end,
        uint256 amount
    ) public canMint(amount) {
        require(hasMinted(msg.sender) == false, "Already minted");
        require(
            start <= block.timestamp && block.timestamp <= end,
            "Invalid period"
        );
        require(
            _isSignedBySigner(
                keccak256(abi.encodePacked(msg.sender, amount, start, end))
                    .toEthSignedMessageHash(),
                _signature,
                signerAddr
            ),
            "Invalid signature"
        );
        _safeMint(msg.sender, amount);
    }

    function airdropMint(address _address, uint256 amount)
        public
        onlyOwner
        canMint(amount)
    {
        _safeMint(_address, amount);
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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function hasMinted(address _address) public view returns (bool) {
        return _numberMinted(_address) > 0;
    }
}