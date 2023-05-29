//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";

contract Devilz is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    using SafeMath for uint256;

    error MaxSupplyExceeded();
    error NotAllowlisted();
    error MaxPerWalletExceeded();
    error InsufficientValue();
    error PublicSaleNotActive();
    error NoContracts();
    error CanNotExceedMaxSupply();
    error AllowlistNotActive();
    error GuaranteedNotActive();

    uint256 public allowlistCost = 0.0666 ether;
    uint256 public guaranteedCost = 0.0666 ether;
    uint256 public publicCost = 0.0666 ether;
    uint256 public maxSupply = 666;
    uint256 public maxSupplyForAllowlist = 666;
    uint256 public maxSupplyForGuaranteed = 666;
    uint256 public amountOwedToDevOne = 2.376 ether;

    uint8 public maxMintAmount = 1;

    string private _baseTokenURI =
        "ipfs://QmaAU8mH19oEvNo5LCA6Rb5HHgPVBh4vdxkRtENUGdSPqr/";

    bool public publicSaleActive;
    bool public allowlistActive;
    bool public guaranteedActive;

    bytes32 private guaranteedMerkleRoot = 0x0;
    bytes32 private allowlistMerkleRoot = 0xbba3b9084ad66bd29f1d14ce67ebf7a2dcef4fbe0df1e37387ea55f5e7583c4b;

    /**
     * @dev Constructor for the Devilz contract.
     * Initializes the ERC721A contract and mints 6 NFTs for the team.
     */
    constructor() ERC721A("Devilz", "DEVILZ") {
        // Mint 6 NFTs to the team.
        _mint(0x1A0E12535AB3fa23b7B7B16D99D0de176d2EBf01, 6);
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    /**
     * @dev Set the maximum supply for allowlist NFTs.
     * @param _maxSupply The new maximum supply for over-allocated NFTs.
     */
    function setMaxSupplyForAllowlist(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply > maxSupply) revert CanNotExceedMaxSupply();
        maxSupplyForAllowlist = _maxSupply;
    }

    /**
     * @dev Toggle the status of allowlist minting.
     */
    function toggleAllowlistActive() external onlyOwner {
        allowlistActive = !allowlistActive;
    }

    /**
     * @dev Toggle the status of guaranteed minting.
     */
    function toggleGuaranteedActive() external onlyOwner {
        guaranteedActive = !guaranteedActive;
    }

    /**
     * @dev Set the maximum supply for guaranteed NFTs.
     * @param _maxSupply The new maximum supply for guaranteed NFTs.
     */
    function setMaxSupplyForGuaranteed(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply > maxSupply) revert CanNotExceedMaxSupply();
        maxSupplyForGuaranteed = _maxSupply;
    }

    /**
     * @dev Set the Merkle root for the allowlist.
     * @param _allowlistMerkleRoot The new Merkle root for the allowlist.
     */
    function setAllowlistMerkleRoot(
        bytes32 _allowlistMerkleRoot
    ) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    /**
     * @dev Set the Merkle root for the guaranteed allowlist.
     * @param _guaranteedMerkleRoot The new Merkle root for the guaranteed allowlist.
     */
    function setGuaranteedMerkleRoot(
        bytes32 _guaranteedMerkleRoot
    ) external onlyOwner {
        guaranteedMerkleRoot = _guaranteedMerkleRoot;
    }

    /**
     * @dev Set the cost for the allowlist sale.
     * @param _newAllowlistCost The new cost for the allowlist sale.
     */
    function setAllowlistCost(uint256 _newAllowlistCost) external onlyOwner {
        allowlistCost = _newAllowlistCost;
    }

    /**
     * @dev Set the cost for the guaranteed sale.
     * @param _newGuaranteedCost The new cost for the presale.
     */
    function setGuaranteedCost(uint256 _newGuaranteedCost) external onlyOwner {
        guaranteedCost = _newGuaranteedCost;
    }

    /**
     * @dev Set the cost for the public sale.
     * @param _newPublicCost The new cost for the public sale.
     */
    function setPublicSaleCost(uint256 _newPublicCost) external onlyOwner {
        publicCost = _newPublicCost;
    }

    /**
     * @dev Mint NFTs for allowlisted users.
     * @param _amount The number of NFTs to mint.
     * @param _proof The Merkle proof for allowlisting.
     */
    function allowlistMint(
        uint8 _amount,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        if (!allowlistActive) revert AllowlistNotActive();
        if (totalSupply() + _amount > maxSupplyForAllowlist)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();
        if (msg.value != allowlistCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
    }

    /**
     * @dev Mint NFTs for guaranteed users.
     * @param _amount The number of NFTs to mint.
     * @param _proof The Merkle proof for allowlisting.
     */
    function guaranteedMint(
        uint8 _amount,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        if (!guaranteedActive) revert GuaranteedNotActive();
        if (totalSupply() + _amount > maxSupplyForGuaranteed)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                guaranteedMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();
        if (msg.value != guaranteedCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
    }

    /**
     * @dev Mint NFTs during the public sale.
     * @param _amount The number of NFTs to mint.
     */
    function mint(uint8 _amount) external payable callerIsUser {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyExceeded();

        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        if (msg.value != publicCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
    }

    /**
     * @dev Airdrop NFTs to the specified addresses.
     * @param targets The list of addresses to receive the airdropped NFTs.
     */
    function airDrop(address[] calldata targets) external onlyOwner {
        if (targets.length + totalSupply() > maxSupply)
            revert MaxSupplyExceeded();

        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
        }
    }

    /**
     * @dev Check if the given user is valid for guaranteed minting.
     * @param _user The user's address.
     * @param _proof The Merkle proof for allowlisting.
     * @return True if the user is valid, otherwise false.
     */
    function isValidGuaranteed(
        address _user,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                guaranteedMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    /**
     * @dev Check if the given user is valid for allowlist minting.
     * @param _user The user's address.
     * @param _proof The Merkle proof for allowlisting.
     * @return True if the user is valid, otherwise false.
     */
    function isValid(
        address _user,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    /**
     * @dev Get the number of NFTs minted by the given user.
     * @param _user The user's address.
     * @return The number of NFTs minted by the user.
     */
    function numberMinted(address _user) external view returns (uint256) {
        return _numberMinted(_user);
    }

    /**
     * @dev Set the maximum number of NFTs that can be minted at once.
     * @param _maxMintAmount The maximum number of NFTs to mint at once.
     */
    function setMaxMintAmount(uint8 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    /**
     * @dev Get the base URI for the NFT metadata.
     * @return The current base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set the base URI for the NFT metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Toggle the public sale status.
     */
    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    /**
     * @dev Transfer an NFT from one address to another.
     * @param from The address of the current owner.
     * @param to The address of the new owner.
     * @param tokenId The ID of the NFT to transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Perform a safe transfer of an NFT from one address to another.
     * @param from The address of the current owner.
     * @param to The address of the new owner.
     * @param tokenId The ID of the NFT to transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Perform a safe transfer of an NFT from one address to another, with additional data.
     * @param from The address of the current owner.
     * @param to The address of the new owner.
     * @param tokenId The ID of the NFT to transfer.
     * @param data Additional data to be sent with the transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Withdraw the contract balance to the contract owner and a specified dev address.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        if (amountOwedToDevOne != 0) {
            if (balance < amountOwedToDevOne) {
                payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(
                    balance
                );
                amountOwedToDevOne = amountOwedToDevOne - balance;
            } else {
                payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(
                    amountOwedToDevOne
                );
                amountOwedToDevOne = 0;
            }
        }

        balance = address(this).balance;

        uint256 payoutA = balance.mul(66).div(100);
        payable(0x9076c1f3D2ce06b0125A65726c7df3988fD8c3fA).transfer(payoutA);

        uint256 payoutB = balance.mul(5).div(100);
        payable(0xC1136C59AC1f85572d1476ED9b98CB1Cc49c38a4).transfer(payoutB);

        uint256 payoutC = balance.mul(5).div(100);
        payable(0xe0320EF76b242107B1ecDa0F6A848eD1125F905d).transfer(payoutC);

        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Emergency withdraw the contract balance to the contract owner and a specified dev address.
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        if (amountOwedToDevOne != 0) {
            if (balance < amountOwedToDevOne) {
                (bool success, ) = payable(
                    0x51aE040f59F2b8E5ea8bc84f8D282adB67571671
                ).call{value: balance}("");
                require(success, "Transfer to devOne failed");
                amountOwedToDevOne = amountOwedToDevOne - balance;
            } else {
                (bool success, ) = payable(
                    0x51aE040f59F2b8E5ea8bc84f8D282adB67571671
                ).call{value: amountOwedToDevOne}("");
                require(success, "Transfer to devOne failed");
                amountOwedToDevOne = 0;
            }
        }

        balance = address(this).balance;

        uint256 payoutA = balance.mul(66).div(100);
        (bool successA, ) = payable(0x9076c1f3D2ce06b0125A65726c7df3988fD8c3fA)
            .call{value: payoutA}("");
        require(successA, "Transfer to address A failed");

        uint256 payoutB = balance.mul(5).div(100);
        (bool successB, ) = payable(0xC1136C59AC1f85572d1476ED9b98CB1Cc49c38a4)
            .call{value: payoutB}("");
        require(successB, "Transfer to address B failed");

        uint256 payoutC = balance.mul(5).div(100);
        (bool successC, ) = payable(0xe0320EF76b242107B1ecDa0F6A848eD1125F905d)
            .call{value: payoutC}("");
        require(successC, "Transfer to address C failed");

        balance = address(this).balance;
        (bool successOwner, ) = payable(msg.sender).call{value: balance}("");
        require(successOwner, "Transfer to owner failed");
    }

    /**
     * @dev Emergency withdraw the contract balance to the contract owner and a specified dev address.
     */
    function lastEmergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        uint256 payoutDev = balance.mul(6).div(100);
        payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671).transfer(payoutDev);

        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}