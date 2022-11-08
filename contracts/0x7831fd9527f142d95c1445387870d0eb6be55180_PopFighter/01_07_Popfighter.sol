// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PopFighter is ERC721A, Ownable, ReentrancyGuard  {

    /**
     * @notice Increment number of Mvp mint token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint16, which will not be an issue as
     * mint quantity should never be greater than 2^16 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function incrementRedemptionsMvp(address to, uint256 _numToIncrement) private {
        (uint16 mvpMintRedemptions, uint16 ogMintRedemptions, uint16 allowListMintRedemptions, uint16 publicMintRedemptions) = unpackMintRedemptions(_getAux(to));
        mvpMintRedemptions += uint16(_numToIncrement);
        _setAux(to, packMintRedemptions(mvpMintRedemptions, ogMintRedemptions, allowListMintRedemptions, publicMintRedemptions));
    }

    /**
     * @notice Increment number of OG mint token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint16, which will not be an issue as
     * mint quantity should never be greater than 2^16 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function incrementRedemptionsOG(address to, uint256 _numToIncrement) private {
        (uint16 MvpMintRedemptions, uint16 ogMintRedemptions, uint16 allowListMintRedemptions, uint16 publicMintRedemptions) = unpackMintRedemptions(_getAux(to));
        ogMintRedemptions += uint16(_numToIncrement);
        _setAux(to, packMintRedemptions(MvpMintRedemptions, ogMintRedemptions, allowListMintRedemptions, publicMintRedemptions));
    }

    /**
     * @notice Increment number of allow list mint token mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint16, which will not be an issue as
     * mint quantity should never be greater than 2^16 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function incrementRedemptionsAllowList(address to, uint256 _numToIncrement) private {
        (uint16 MvpMintRedemptions, uint16 ogMintRedemptions, uint16 allowListMintRedemptions, uint16 publicMintRedemptions) = unpackMintRedemptions(_getAux(to));
        allowListMintRedemptions += uint16(_numToIncrement);
        _setAux(to, packMintRedemptions(MvpMintRedemptions, ogMintRedemptions, allowListMintRedemptions, publicMintRedemptions));
    }

    /**
     * @notice Increment number of public sale mints redeemed by caller
     * @dev We cast the _numToIncrement argument into uint16, which will not be an issue as
     * mint quantity should never be greater than 2^16 - 1.
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function incrementRedemptionsPublic(address to, uint256 _numToIncrement) private {
        (uint16 MvpMintRedemptions, uint16 ogMintRedemptions, uint16 allowListMintRedemptions, uint16 publicMintRedemptions) = unpackMintRedemptions(_getAux(to));
        publicMintRedemptions += uint16(_numToIncrement);
        _setAux(to, packMintRedemptions(MvpMintRedemptions, ogMintRedemptions, allowListMintRedemptions, publicMintRedemptions));
    }

    /**
     * @notice Unpack and get number of Mvp mints redeemed by caller
     * @return number of Mvp redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function getRedemptionsMvp(address from) public view returns (uint256) {
        (uint16 mvpMintRedemptions, , , ) = unpackMintRedemptions(_getAux(from));
        return mvpMintRedemptions;
    }

    /**
     * @notice Unpack and get number of og mints redeemed by caller
     * @return number of public redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function getRedemptionsOG(address from) public view returns (uint256) {
        (, uint16 ogMintRedemptions, , ) = unpackMintRedemptions(_getAux(from));
        return ogMintRedemptions;
    }

    /**
     * @notice Unpack and get number of allow list mints redeemed by caller
     * @return number of allow list redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function getRedemptionsAllowList(address from) public view returns (uint256) {
        (, , uint16 allowListMintRedemptions, ) = unpackMintRedemptions(_getAux(from));
        return allowListMintRedemptions;
    }

    /**
     * @notice Unpack and get number of public mints redeemed by caller
     * @return number of public redemptions used
     * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
     */
    function getRedemptionsPublic(address from) public view returns (uint256) {
        (, , , uint16 publicMintRedemptions) = unpackMintRedemptions(_getAux(from));
        return publicMintRedemptions;
    }

    /**
     * @notice Pack four uint16s into a single uint64 value
     * @return Packed value
     * @dev Performs shift and bit operations to pack four uint16s into a single uint64
     */
    function packMintRedemptions(uint16 _mvpMintRedemptions, uint16 _ogMintRedemptions, uint16 _allowListMintRedemptions, uint16 _publicMintRedemptions) private pure returns (uint64) {
        return (uint64(_mvpMintRedemptions) << 48) | (uint64(_ogMintRedemptions) << 32) | (uint64(_allowListMintRedemptions) << 16) | uint64(_publicMintRedemptions);
    }

    /**
     * @notice Unpack a single uint64 value into four uint16s
     * @return mvpMintRedemptions ogMintRedemptions allowListMintRedemptions publicMintRedemptions Unpacked values
     * @dev Performs shift and bit operations to unpack a single uint64 into four uint16s
     */
    function unpackMintRedemptions(uint64 _mintRedemptionPack) private pure returns (uint16 mvpMintRedemptions, uint16 ogMintRedemptions, uint16 allowListMintRedemptions, uint16 publicMintRedemptions) {
        mvpMintRedemptions = uint16(_mintRedemptionPack >> 48 & 0x000000000000ffff);
        ogMintRedemptions = uint16(_mintRedemptionPack >> 32 & 0x000000000000ffff);
        allowListMintRedemptions = uint16(_mintRedemptionPack >> 16 & 0x000000000000ffff);
        publicMintRedemptions = uint16(_mintRedemptionPack & 0x000000000000ffff);
    }

    enum MintPhase {
        NOT_START,
        MVP_FREE_MINT,
        OG_AL_MINT,
        PUBLIC_SALE
    }

    MintPhase public currentMintPhase = MintPhase.NOT_START;

    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        currentMintPhase = _mintPhase;
    }

    modifier inMintPhase(MintPhase requireMintPhase) {
        require(requireMintPhase == currentMintPhase, "Not in correct mint phase.");
        _;
    }

    string public baseURI;

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    uint256 collectionSize = 5500;

    uint256 public alMintPrice = 0.016 ether;

    uint256 public publicSalePrice = 0.02 ether;

    constructor() ERC721A("Pop Fighter", "PF") {}

    /**
     * MVP Mint Module
     */

    bytes32 private mvpMintRoot;

    uint256 public mvpMintStock = 800;

    function setMvpMintRoot(bytes32 _root) external onlyOwner {
        mvpMintRoot = _root;
    }

    function isMvp(address from, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return MerkleProof.verify(proof, mvpMintRoot, leaf);
    }

    function mvpFreeMint(bytes32[] calldata proof) external inMintPhase(MintPhase.MVP_FREE_MINT) {
        require(isMvp(msg.sender, proof), "Invalid merkle proof.");
        require(getRedemptionsMvp(msg.sender) == 0, "Minted.");
        require(mvpMintStock >= 1, "Exceed mvp mint supply.");
        _safeMint(msg.sender, 1);
        unchecked {
            mvpMintStock--;
        }
        incrementRedemptionsMvp(msg.sender, 1);
    }

    /**
     * OG Mint Module
     */

    uint256 public ogALStock = 2300;

    bytes32 private ogMintRoot;

    function setOGMintRoot(bytes32 _root) external onlyOwner {
        ogMintRoot = _root;
    }

    function isOG(address from, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return MerkleProof.verify(proof, ogMintRoot, leaf);
    }

    function ogMvpMint(uint256 amount, bytes32[] calldata proof) public payable inMintPhase(MintPhase.OG_AL_MINT) {
        require(isOG(msg.sender, proof) || isMvp(msg.sender, proof), "Invalid merkle proof.");
        require(getRedemptionsOG(msg.sender) + amount <= 2, "Exceed num per address.");
        require(msg.value == alMintPrice * amount, "Value not valid.");
        require(ogALStock >= amount, "Exceed max supply.");
        _safeMint(msg.sender, amount);
        unchecked{
            ogALStock -= amount;
        }
        incrementRedemptionsOG(msg.sender, amount);
    }

    /**
     * Allow List Mint Module
     */

    bytes32 private allowListMintRoot;

    function setALMintRoot(bytes32 _root) external onlyOwner {
        allowListMintRoot = _root;
    }

    function isInAllowList(address from, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return MerkleProof.verify(proof, allowListMintRoot, leaf);
    }

    function allowListMint(bytes32[] calldata proof) public payable inMintPhase(MintPhase.OG_AL_MINT) {
        require(isInAllowList(msg.sender, proof), "Invalid merkle proof.");
        require(getRedemptionsAllowList(msg.sender) == 0, "Minted.");
        require(msg.value == alMintPrice, "Value not valid.");
        require(ogALStock >= 1, "Exceed max supply.");
        _safeMint(msg.sender, 1);
        unchecked{
            ogALStock -= 1;
        }
        incrementRedemptionsAllowList(msg.sender, 1);
    }

    /**
     * Public Sale Mint Module
     */

    function publicSaleMint(uint256 amount) public payable inMintPhase(MintPhase.PUBLIC_SALE) {
        require(getRedemptionsPublic(msg.sender) + amount <= 2, "Exceed num per address.");
        require(msg.value == publicSalePrice * amount, "Value not valid.");
        require(totalSupply() + amount <= collectionSize, "Exceed total supply.");
        _safeMint(msg.sender, amount);
        incrementRedemptionsPublic(msg.sender, amount);
    }

    /**
     * Utils Module
     */
    function airdrop(address[] calldata toList, uint256[] calldata quantities) external onlyOwner {
        for (uint256 i = 0; i < toList.length; i++) {
            require(totalSupply() + quantities[i] <= collectionSize, "Exceed max supply.");
            _safeMint(toList[i], quantities[i]);
        }
    }

    function withdraw() external onlyOwner {
        address shareHolder1 = 0x03510854B98E8a55a3f7Dc691547AcCF983A7df8;
        address shareHolder2 = 0x694C8Af4Dd3aDE21645F39857CE66A6c65857694;
        if (address(this).balance < 30 ether) {
            (bool success, ) = shareHolder1.call{value: address(this).balance}("");
            require(success, "transfer failed");
        } else {
            (bool success, ) = shareHolder2.call{value: 30 ether}("");
            require(success, "transfer failed");
            (success, ) = shareHolder2.call{value: address(this).balance * 3 / 10}("");
            require(success, "transfer failed");
            (success, ) = shareHolder1.call{value: address(this).balance}("");
            require(success, "transfer failed");
        }
    }
}