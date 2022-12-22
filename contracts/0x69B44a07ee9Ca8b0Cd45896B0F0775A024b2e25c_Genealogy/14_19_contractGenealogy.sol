// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Utils/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// File: contracts/EnumerableERC721A.sol

pragma solidity ^0.8.7;

interface ERC721Partial {
    function mint(
        address _to,
        uint256 _tokenId,
        bool[6] calldata _isEquipped,
        uint256[6] calldata _accessoryTokenIds
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// @title KPK Project

contract Genealogy is
    ERC721A,
    PaymentSplitter,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    //To concatenate the URL of an NFT
    using Strings for uint256;

    //To check the addresses in the whitelist
    bytes32 private mR;
    //Number of NFTs in the collection
    uint256 public constant MAX_SUPPLY = 5555;

    //Maximum number of NFTs an address can mint
    uint256 public max_mint_allowed = 0;
    //Price of one NFT in presale
    uint256 public price = 0.022 ether;

    //URI of the NFTs when revealed
    string private baseURI;
    //URI of the NFTs when not revealed
    string private notRevealedURI;
    //The extension of the file containing the Metadatas of the NFTs
    string public baseExtension = ".json";

    //Are the NFTs revealed yet ?
    bool public revealed = false;

    //Is the contract paused ?
    bool public paused = false;
   //Keep a track of the number of tokens per address
    address[]  public walletAddress;
    //The different Phase of metadata
    enum Phase {
        Before,
        Presale,
        Phase1,
        Phase2,
        Phase3,
        Public,
        SoldOut
    }

    Phase public phaseStep;
    //Owner of the smart contract

    address private _owner;

    //Keep a track of the number of tokens per address
    mapping(address => uint256) nftsPerWallet;

 
    //Addresses of all the members of the team
    address[] private _team = [0x5B1a4ebd28b597fe47494A0a5766b2Eb6e6B3fcC];

    //Shares of all the members of the team
    uint256[] private _teamShares = [100];

    //Genesis contract
    ERC721Partial tokenContract;

    //Constructor of the collection
    constructor()
        ERC721A("Genealogy", "KPKG")
        PaymentSplitter(_team, _teamShares)
    {
        transferOwnership(msg.sender);
        phaseStep = Phase.Before;
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Edit the Merkle Root
     *
     * @param _newMerkleRoot The new Merkle Root
     **/
    function changeMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        mR = _newMerkleRoot;
    }

    /**
     * @notice Initialise Merkle Root
     *
     * @param _theBaseURI Base URI
     * @param _notRevealedURI Hide base URI
     * @param _merkleRoot The new Merkle Root
     **/
    function init(
        string memory _theBaseURI,
        string memory _notRevealedURI,
        bytes32 _merkleRoot
    ) external onlyOwner {
        mR = _merkleRoot;
        baseURI = _theBaseURI;
        notRevealedURI = _notRevealedURI;
    }

    /**
     * @notice Set pause to true or false
     *
     * @param _paused True or false if you want the contract to be paused or not
     **/
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /**
     * @notice Set ancestor contract
     *
     * @param _tokenContract contract address for ancestors
     **/
    function setAncestorContract(ERC721Partial _tokenContract)
        external
        onlyOwner
    {
        tokenContract = _tokenContract;
    }

    /**
     * @notice Allows to set the revealed variable to true
     **/
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**
     * @notice Change the base URI
     *
     * @param _newBaseURI The new base URI
     **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Change the not revealed URI
     *
     * @param _notRevealedURI The new not revealed URI
     **/
    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function getAmountMinted(address minter) public view returns (uint256) {
        return nftsPerWallet[minter];
    }

    /**
     * @notice Return mapping of a mint phase
     *
     * @return The URI of the NFTs when revealed
     **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Allows to change the base extension of the metadatas files
     *
     * @param _baseExtension the new extension of the metadatas files
     **/
    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    /**
     * @notice Allows to change the sellinStep to Presale
     **/
    function setUpPresale(bytes32 _newMerkleRoot) external onlyOwner {
        mR = _newMerkleRoot;
        phaseStep = Phase.Presale;
        price = 0.022 ether;
        resetBalance(walletAddress);
        delete walletAddress;
    }

    /**
     * @notice Allows to change the sellinStep to Presale
     **/
    function setUpPhase1(bytes32 _newMerkleRoot) external onlyOwner {
        mR = _newMerkleRoot;
        phaseStep = Phase.Phase1;
        price = 0.022 ether;
        resetBalance(walletAddress);
        delete walletAddress;
    }

    /**
     * @notice Allows to change the sellinStep to Presale
     **/
    function setUpPhase2(bytes32 _newMerkleRoot) external onlyOwner {
        mR = _newMerkleRoot;
        phaseStep = Phase.Phase2;
        price = 0.033 ether;
        resetBalance(walletAddress);
        delete walletAddress;
    }

    /**
     * @notice Allows to change the sellinStep to Presale
     **/
    function setUpPhase3(bytes32 _newMerkleRoot) external onlyOwner {
        mR = _newMerkleRoot;
        phaseStep = Phase.Phase3;
        price = 0.033 ether;
        resetBalance(walletAddress);
        delete walletAddress;
    }

    /**
     * @notice Allows to change the sellinStep to Presale
     **/
    function setUpPublic() external onlyOwner {
        phaseStep = Phase.Public;
        max_mint_allowed = 1;
        price = 0.033 ether;
        resetBalance(walletAddress);
    }

    /**
     * @notice Allows to mint NFTs
     *
     * @param addresses Array of address to delete from mapping
     **/
    function resetBalance(address[] memory addresses) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            nftsPerWallet[addresses[i]] = 0;
        }
    }

    /**
     * @notice Allows to mint one NFT if whitelisted
     *
     *
     * @param _proof The Merkle Proof
     * @param _amount The ammount of NFTs the user wants to mint
     **/
    function presaleMint(
        bytes32[] calldata _proof,
        uint256 _amount,
        uint256 _maxAmount
    ) external payable nonReentrant {
        //Are we in Presale ?
        require(!paused, "Break time...");
        uint256 numberNftSold = totalSupply();
        require(phaseStep != Phase.SoldOut, "Sorry, no NFTs left.");
        //Did this account already mint an NFT ?
        require(
            nftsPerWallet[msg.sender] + _amount <= _maxAmount,
            string(abi.encodePacked("You can't mint that much"))
        );
        //Did the user send enought Ethers ?
        require(msg.value >= price * _amount, "Not enought funds.");
        //If the user try to mint any non-existent token
        require(
            numberNftSold + _amount <= MAX_SUPPLY,
            "Sale is almost done and we don't have enought NFTs left."
        );
        if (phaseStep != Phase.Public) {
            //Is this user on the whitelist ?
            require(
                isWhiteListed(msg.sender, _proof),
                "You are not whitelisted to mint"
            );
        }
        //Increment the number of NFTs this user minted
        nftsPerWallet[msg.sender] += _amount;
        walletAddress.push(msg.sender);

        //Mint the user NFT
        _safeMint(msg.sender, _amount);

        //If this account minted the last NFTs available
        if (numberNftSold + _amount == MAX_SUPPLY) {
            phaseStep = Phase.SoldOut;
        }
    }

    /**
     * @notice Allows to mint NFTs
     *
     * @param tokenID The ammount of NFTs the user wants to mint
     **/
    function mintAncestor(uint256 tokenID) external payable nonReentrant {
        require(msg.sender == ownerOf(tokenID), "You don't own this token.");

        //Minting all the account NFTs
        tokenContract.mint(
            msg.sender,
            tokenID,
            [false, false, false, false, false, false],
            [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ]
        );
        _burn(tokenID);
    }

    /**
     * @notice Allows to gift one NFT to an address
     *
     * @param _account The account of the happy new owner of one NFT
     **/
    function gift(address _account) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_SUPPLY, "Sold out");
        _safeMint(_account, 1);
    }

    /**
     * @notice Return true or false if the account is whitelisted or not
     *
     * @param account The account of the user
     * @param proof The Merkle Proof
     *
     * @return true or false if the account is whitelisted or not
     **/
    function isWhiteListed(address account, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof);
    }

    /**
     * @notice Return the account hashed
     *
     * @param account The account to hash
     *
     * @return The account hashed
     **/
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /**
     * @notice Returns true if a leaf can be proved to be a part of a Merkle tree defined by root
     *
     * @param leaf The leaf
     * @param proof The Merkle Proof
     *
     * @return True if a leaf can be provded to be a part of a Merkle tree defined by root
     **/
    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, mR, leaf);
    }

    /**
     * @notice Allows to get the complete URI of a specific NFT by his ID
     *
     * @param _nftId The id of the NFT
     *
     * @return The token URI of the NFT which has _nftId Id
     **/
    function tokenURI(uint256 _nftId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_nftId), "This NFT doesn't exist.");

        string memory currentBaseURI = _baseURI();
        if (phaseStep == Phase.Presale || !revealed) {
            return notRevealedURI;
        }
        if (phaseStep == Phase.Phase1) {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            "Phase1/metadata/",
                            _nftId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        } else {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            "Phase2/metadata/",
                            _nftId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}