// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract ShopNEXT_NFT_Card is ERC721,ERC721Enumerable, Ownable {
    event AddSigner(address indexed signer);
    event RemoveSigner(address indexed signer);
    event MintNFT(address indexed user, uint256 indexed nftId);
    event ClaimNFT(address indexed user, uint256 indexed nftId);

    mapping(address => bool) public signers;
    mapping(bytes =>bool) public isClaimed;
    string public _baseNftCardURI;

    constructor() ERC721("ShopNEXT NFT Card", "NFTCard") {
        signers[msg.sender] = true;
    }
    function claimNft(
        address to,
        uint256 tokenId,
        bytes calldata signature
    ) external {
        require(!isClaimed[signature],"SN: signature claimed");
        require(!_exists(tokenId),"SN: NftCardID exist");
        bytes32 _msgHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked("SN_CARD_GENERATE", to, tokenId))
            )
        );

        address signer = getSigner(_msgHash, signature);
        require(signers[signer], "SN: invalid signer");
        isClaimed[signature] = true;
        _safeMint(to, tokenId);
        emit ClaimNFT(to, tokenId);
    }
    function setBaseURI(string calldata uri) external onlyOwner{
        _baseNftCardURI = uri;
    }
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId),"SN: NftCardID exist");
        _safeMint(to, tokenId);
        emit MintNFT(to, tokenId);
    }
    function addSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0) && !signers[_signer],
            "SN: invalid address"
        );
        signers[_signer] = true;
        emit AddSigner(_signer);
    }
    function removeSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0) && signers[_signer],
            "SN: invalid address"
        );
        signers[_signer] = false;
        emit RemoveSigner(_signer);
    }
    function getSigner(bytes32 msgHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(msgHash, v, r, s);
    }
    function splitSignature(bytes memory signature)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "SN: invalid signature length");
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseNftCardURI;
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}