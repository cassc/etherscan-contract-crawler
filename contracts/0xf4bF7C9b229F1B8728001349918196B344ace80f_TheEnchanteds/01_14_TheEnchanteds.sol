// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IARTIFACT.sol";
import "./IERC2981.sol";

/**
 * @title TheEnchanteds
 * TheEnchanteds - Smart contract for Enchanted Valley characters
 */
contract TheEnchanteds is ERC721, Ownable {
    using MerkleProof for bytes32[];

    address private _royaltiesReceiver;
    uint256 public _royaltiesPercentage = 5;
    string public contract_ipfs_json;
    bytes32 public MERKLE_ROOT;
    uint256 HARD_CAP = 11000;
    uint256 SOFT_CAP = 2200;
    uint256 public minting_price = 0.08 ether;
    uint256 public selling_tribe = 0;
    uint256 MAX_AMOUNT = 3;
    bool public whitelist_active = false;
    bool public sale_active = false;
    address public gnosis_vault;

    mapping(uint256 => bool) public claimed_artifacts;
    mapping(uint256 => uint256) private token_ids;
    mapping(uint256 => string) public tribe_uris;

    IARTIFACT private ARTIFACT;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _contract_ipfs,
        address _artifactAddress,
        address _gnosis_vault
    ) ERC721(_name, _ticker) {
        contract_ipfs_json = _contract_ipfs;
        ARTIFACT = IARTIFACT(_artifactAddress);
        tribe_uris[0] = "https://enchanted-valley-api-kwvlp.ondigitalocean.app/";
        tribe_uris[1] = "https://enchanted-valley-api-kwvlp.ondigitalocean.app/";
        tribe_uris[2] = "https://enchanted-valley-api-kwvlp.ondigitalocean.app/";
        tribe_uris[3] = "https://enchanted-valley-api-kwvlp.ondigitalocean.app/";
        tribe_uris[4] = "https://enchanted-valley-api-kwvlp.ondigitalocean.app/";
        gnosis_vault = _gnosis_vault;
    }

    /*
        This method will return token uri
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _tknId = Strings.toString(_tokenId);
        uint256 tribe = 0;
        if (_tokenId > 2200 && _tokenId <= 4400) {
            tribe = 1;
        } else if (_tokenId > 4400 && _tokenId <= 6600) {
            tribe = 2;
        } else if (_tokenId > 6600 && _tokenId <= 8800) {
            tribe = 3;
        } else if (_tokenId > 8800 && _tokenId <= 11000) {
            tribe = 4;
        }

        return string(abi.encodePacked(tribe_uris[tribe], _tknId, ".json"));
    }

    /*
        This method will return public contract uri
    */
    function contractURI() public view returns (string memory) {
        return contract_ipfs_json;
    }

    /*
        This method will receiver
    */
    function royaltiesReceiver() external view returns (address) {
        return _royaltiesReceiver;
    }

    /*
        This method will return all tokens owned by an address
    */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = totalSupply();
            uint256 resultIndex = 0;
            uint256 nftId;

            for (nftId = 1; nftId <= totalNFTs; nftId++) {
                if (ownerOf(nftId) == _owner) {
                    result[resultIndex] = nftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /*
        This method will return all artifacts owned by an address
    */
    function artifactsOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = ARTIFACT.balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = ARTIFACT.totalSupply();
            uint256 resultIndex = 0;
            uint256 nftId;

            for (nftId = 1; nftId <= totalNFTs; nftId++) {
                if (ARTIFACT.ownerOf(nftId) == _owner) {
                    result[resultIndex] = nftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /*
        This method will allow users to claim the artifact
    */
    function claimArtifact(uint256[] calldata _artifacts, uint256 _tribe)
        public
    {
        uint256 artifact_balance = ARTIFACT.balanceOf(msg.sender);
        require(
            artifact_balance > 0 &&
                tx.origin == msg.sender &&
                selling_tribe >= _tribe,
            "You don't own any artifact, you're a contract or trying to claim an unallowed tribe"
        );
        uint256 j = 0;
        for (j = 0; j < _artifacts.length; j++) {
            address owner = ARTIFACT.ownerOf(_artifacts[j]);
            require(
                owner == msg.sender &&
                    claimed_artifacts[_artifacts[j]] == false,
                "Trying to claim a token you don't own or artifact claimed yet"
            );
            uint256 reached_hardcap = totalSupply() + 1;
            uint256 reached_softcap = token_ids[_tribe] + 1;
            require(
                reached_hardcap <= HARD_CAP && reached_softcap <= SOFT_CAP,
                "Max amount reached."
            );
            claimed_artifacts[_artifacts[j]] = true;
            token_ids[_tribe]++;
            uint256 nextId = (2200 * _tribe) + token_ids[_tribe];
            _mint(msg.sender, nextId);
        }
    }

    /*
        This method will return the state of the artifact
    */
    function isArtifactClaimed(uint256 _tokenId) public view returns (bool) {
        return claimed_artifacts[_tokenId];
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        require(whitelist_active, "Whitelist is not active");
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = false;
        whitelisted = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        uint256 tokenCount = balanceOf(_address);
        if (tokenCount > 0) {
            whitelisted = true;
        }
        return whitelisted;
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT(bytes32[] calldata _merkleProof, uint256 _tribe)
        public
        payable
    {
        require(
            tx.origin == msg.sender && sale_active && selling_tribe >= _tribe,
            "Can't buy because sale is not active or tribe is not selling"
        );
        bool canMint = false;
        uint256 maxAmount = MAX_AMOUNT;
        if (whitelist_active) {
            canMint = ARTIFACT.balanceOf(msg.sender) > 0;
            if (!canMint) {
                canMint = balanceOf(msg.sender) > 0;
            }
            if (!canMint) {
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                canMint = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
            }
        } else {
            canMint = true;
        }
        require(
            canMint && msg.value % minting_price == 0,
            "Sorry you can't mint right now"
        );
        uint256 amount = msg.value / minting_price;
        require(
            amount >= 1 && amount <= maxAmount,
            "Amount should be at least 1 and must be less or equal to 3"
        );
        uint256 reached_hardcap = amount + totalSupply();
        uint256 reached_softcap = token_ids[_tribe] + amount;
        require(
            reached_hardcap <= HARD_CAP && reached_softcap <= SOFT_CAP,
            "Max amount reached."
        );
        uint256 j = 0;
        for (j = 0; j < amount; j++) {
            token_ids[_tribe]++;
            uint256 nextId = (2200 * _tribe) + token_ids[_tribe];
            _mint(msg.sender, nextId);
        }
    }

    /*
        This method will allow owner to mint tokens
    */
    function ownerMint(uint256 _amount, uint256 _tribe) public onlyOwner {
        require(_amount >= 1, "Amount should be at least 1");
        uint256 reached_hardcap = _amount + totalSupply();
        uint256 reached_softcap = token_ids[_tribe] + _amount;
        require(
            reached_hardcap <= HARD_CAP && reached_softcap <= SOFT_CAP,
            "Max amount reached."
        );
        uint256 j = 0;
        for (j = 0; j < _amount; j++) {
            token_ids[_tribe]++;
            uint256 nextId = (2200 * _tribe) + token_ids[_tribe];
            _mint(msg.sender, nextId);
        }
    }

    /*
        This method will return total supply
    */
    function totalSupply() public view returns (uint256) {
        return
            token_ids[0] +
            token_ids[1] +
            token_ids[2] +
            token_ids[3] +
            token_ids[4];
    }

    /*
        This method will return royalty info
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_tokenId > 0, "Asking royalties for non-existent token");
        uint256 _royalties = (_salePrice * _royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }

    /*
        This method return the artifact balance
    */
    function artifactBalance(address _address) public view returns (uint256) {
        uint256 balance = ARTIFACT.balanceOf(_address);
        return balance;
    }

    /*
        This method will allow owner to change the gnosis safe wallet
    */
    function fixGnosis(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Can't use black hole.");
        gnosis_vault = newAddress;
    }

    /*
        This method will allow owner to fix royalties receiver
    */
    function fixRoyaltiesParams(
        address newRoyaltiesReceiver,
        uint256 newRoyaltiesPercentage
    ) external onlyOwner {
        _royaltiesReceiver = newRoyaltiesReceiver;
        _royaltiesPercentage = newRoyaltiesPercentage;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSellingTribe(uint256 newTribe) external onlyOwner {
        selling_tribe = newTribe;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSaleState(bool newState) external onlyOwner {
        sale_active = newState;
    }

    /*
        This method will allow owner to fix max amount of nfts per minting
    */
    function fixMaxAmount(uint256 newMax) external onlyOwner {
        MAX_AMOUNT = newMax;
    }

    /*
        This method will allow owner to set the merkle root
    */
    function fixMerkleRoot(bytes32 root) external onlyOwner {
        MERKLE_ROOT = root;
    }

    /*
        This method will allow owner to fix the contract details
    */
    function fixContractDescription(string memory newDescription)
        external
        onlyOwner
    {
        contract_ipfs_json = newDescription;
    }

    /*
        This method will allow owner to fix the artifact address
    */
    function fixArtifactAddress(address _artifactAddress) external onlyOwner {
        ARTIFACT = IARTIFACT(_artifactAddress);
    }

    /*
        This method will allow owner to fix the minting price
    */
    function fixPrice(uint256 price) external onlyOwner {
        minting_price = price;
    }

    /*
        This method will allow owner to fix the whitelist role
    */
    function fixWhitelist(bool state) external onlyOwner {
        whitelist_active = state;
    }

    /*
        This method will allow owner to fix tribe base uri
    */
    function fixTribeURI(uint256 _tribe, string memory _newURI)
        external
        onlyOwner
    {
        tribe_uris[_tribe] = _newURI;
    }

    /*
        This method will return current token id
    */
    function returnTribeSupply(uint256 _tribe) external view returns (uint256) {
        return token_ids[_tribe];
    }

    /*
        This method will allow owner to withdraw all ethers
    */
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        require(
            gnosis_vault != address(0) && balance > 0,
            "Can't withdraw on black hole."
        );
        bool success;
        (success, ) = gnosis_vault.call{value: balance}("");
        require(success, "recipient failed to receive");
    }

    /*
        Registering support interface
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}