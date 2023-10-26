// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Musess
 */
contract Musess is ERC721, Ownable {
    using Counters for Counters.Counter;
    bool public sale_active = false;
    string public contract_ipfs_json;
    Counters.Counter private token_id_counter;
    uint256 public minting_price_presale = 0.15 ether;
    uint256 public minting_price_sale = 0.18 ether;
    uint256 public HARD_CAP = 999;
    uint256 public SOFT_CAP = 990;
    uint256 public MAX_AMOUNT = 20;
    bytes32 public MERKLE_ROOT_PRESALE;
    bytes32 public MERKLE_ROOT_FREE;
    bool public is_collection_revealed = false;
    bool public is_collection_locked = false;
    string public notrevealed_nft = "https://musess-api-otpxj.ondigitalocean.app/nft/unrevealed";
    string public contract_base_uri;
    address public vault_address;
    mapping(address => bool) minted_whitelist;

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {}

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return token_id_counter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (is_collection_revealed == true) {
            string memory _tknId = Strings.toString(_tokenId);
            return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
        } else {
            return notrevealed_nft;
        }
    }

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
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function contractURI() public view returns (string memory) {
        return contract_ipfs_json;
    }

    function fixURIs(uint8 _type, string memory _newURI) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        if (_type == 0) {
            contract_base_uri = _newURI;
        } else if (_type == 1) {
            notrevealed_nft = _newURI;
        } else if (_type == 3) {
            contract_ipfs_json = _newURI;
        }
    }

    /*
        This method will allow owner reveal the collection
     */

    function revealCollection() external onlyOwner {
        is_collection_revealed = true;
    }

    /*
        This method will allow owner lock the collection
     */

    function lockCollection() external onlyOwner {
        is_collection_locked = true;
    }

    /*
        This method will allow owner to start and stop the sale
    */
    function fixSaleState(bool _newState) external onlyOwner {
        sale_active = _newState;
    }

    /*
        This method will allow owner to fix max amount of nfts per minting
    */
    function fixMaxAmount(uint256 _newMax) external onlyOwner {
        require(!is_collection_locked, "Collection locked");
        MAX_AMOUNT = _newMax;
    }

    /*
        This method will allow owner to fix the minting price
    */
    function fixPrice(uint256 _price, uint8 _priceType) external onlyOwner {
        if (_priceType == 1) {
            minting_price_presale = _price;
        } else {
            minting_price_sale = _price;
        }
    }

    /*
        This method will allow owner to change the gnosis safe wallet
    */
    function fixVault(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Can't use black hole");
        vault_address = _newAddress;
    }

    /*
        This method will allow owner to set the merkle root
    */
    function fixMerkleRoot(bytes32 _root, uint8 _listType) external onlyOwner {
        if (_listType == 1) {
            MERKLE_ROOT_PRESALE = _root;
        } else {
            MERKLE_ROOT_FREE = _root;
        }
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function dropNFT(address _to, uint256 _amount) external onlyOwner {
        uint256 reached = token_id_counter.current() + _amount;
        require(reached <= HARD_CAP, "Hard cap reached");
        for (uint256 j = 1; j <= _amount; j++) {
            token_id_counter.increment();
            uint256 newTokenId = token_id_counter.current();
            _mint(_to, newTokenId);
        }
    }

    /*
        This method will claim the free nft
    */
    function claimNFT(bytes32[] calldata _merkleProof) external {
        require(
            (token_id_counter.current() + 1) <= SOFT_CAP,
            "Hard cap reached"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool whitelisted = MerkleProof.verify(
            _merkleProof,
            MERKLE_ROOT_FREE,
            leaf
        );
        require(
            whitelisted && !minted_whitelist[msg.sender],
            "Not whitelisted or minted yet"
        );
        minted_whitelist[msg.sender] = true;
        token_id_counter.increment();
        uint256 id = token_id_counter.current();
        _mint(msg.sender, id);
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT(bytes32[] calldata _merkleProof) external payable {
        require(sale_active, "Can't buy because sale is not active");
        bool isWhitelisted = false;
        uint256 minting_price = minting_price_sale;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        isWhitelisted = MerkleProof.verify(
            _merkleProof,
            MERKLE_ROOT_PRESALE,
            leaf
        );
        if (isWhitelisted) {
            minting_price = minting_price_presale;
        }
        require(
            msg.value % minting_price == 0 && msg.value > 0,
            "Not in whitelist or price is wrong"
        );
        uint256 amount = msg.value / minting_price;
        require(
            amount >= 1 && amount <= MAX_AMOUNT,
            "Amount should be at least 1 and must be less or equal to max amount"
        );
        require((amount + totalSupply()) <= SOFT_CAP, "Soft cap reached");
        uint256 j = 0;
        for (j = 0; j < amount; j++) {
            token_id_counter.increment();
            uint256 id = token_id_counter.current();
            _mint(msg.sender, id);
        }
    }

    /*
        This method will allow owner to withdraw all ethers
    */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(vault_address != address(0) && balance > 0, "Can't withdraw");
        bool success;
        (success, ) = vault_address.call{value: balance}("");
        require(success, "Withdraw to vault failed");
    }
}