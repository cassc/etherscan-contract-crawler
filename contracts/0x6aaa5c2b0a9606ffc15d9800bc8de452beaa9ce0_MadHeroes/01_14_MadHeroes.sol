// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MadHeroes is Ownable, ERC1155, IERC2981 {
    using Strings for string;

    address private proxyRegistryAddress;

    string private baseUri;
    uint256 constant maxTokens = 2000;

    uint256 private _currentTokenID = 0;

    /*
     * Sale price and settings
     */
    uint256 publicPrice = 0.17 ether;
    uint256 whitelistPrice = 0.13 ether;
    uint256 whitelistTokenPerPerson = 20;
    uint32 wlStartTime;
    uint32 publicStartTime;
    bytes32 wlRoot;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    //wallets of projects
    address public projectWallet;
    address public communityWallet;
    address public royaltyWallet;
    uint256 private communityRate;
    uint256 private royaltyRate;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _projectWallet,
        address _communityWallet,
        address _royaltyWallet,
        uint256 _communityRate,
        uint256 _royaltyRate,
        uint32 _wlStartTime,
        uint32 _publicStartTime,
        address _proxyRegistryAddress
    ) ERC1155(_uri) {
        communityWallet = _communityWallet;
        communityRate = _communityRate;
        royaltyWallet = _royaltyWallet;
        royaltyRate = _royaltyRate;
        projectWallet = _projectWallet;
        name = _name;
        symbol = _symbol;
        baseUri = _uri;
        wlStartTime = _wlStartTime;
        publicStartTime = _publicStartTime;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC721 metadata.
     */
    function uri(uint256 _optionId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                baseUri,
                Strings.toString(_optionId),
                ".json"
            )
        );
    }

    function setUri(string memory _newURI) external onlyOwner {
        baseUri = _newURI;
    }

    /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
    function _getNextTokenID() private returns (uint256) {
        _currentTokenID = _currentTokenID + 1;
        return _currentTokenID;
    }

    /**
     * @dev Get already minted count
     */
    function mintedCount() external view returns (uint256) {
        return _currentTokenID;
    }

    /**
     * @dev Change Porxy address to give factory access to free minting from OpenSea
     * In that case money will be automatically send to project's wallet
     * @param proxy address of the contract that will have free access
     */
    function setProxy(address proxy) external onlyOwner {
        proxyRegistryAddress = proxy;
    }

    /**
     * @dev Configure Whitelist start, set time, price and root fot the merkel proof
     * @param startTime time to start whitelist sales
     * @param newPrice price for the whitelist sales
     * @param root Merkle tree root
     */
    function setWlStart(uint32 startTime, uint256 newPrice, bytes32 root) external onlyOwner {
        wlStartTime = startTime;
        whitelistPrice = newPrice;
        wlRoot = root;
    }

    /**
     * @dev Configure Public start, set time and price for it
     * @param startTime time to start whitelist sales
     * @param newPrice price for the whitelist sales
     */
    function setPublicStart(uint32 startTime, uint256 newPrice) external onlyOwner {
        publicStartTime = startTime;
        publicPrice = newPrice;
    }

    /**
     * @dev Whitelist minting function
     * Do minting only for whitelist users, and mint to message sender
     * MerkleTree used to validate person included in whitelist
     * @param amount number of tokens to mint
     * @param proof MerkleTree proof for sender to check
     * @param data additional transaction data
     */
    function whitelistMint(
        uint256 amount,
        bytes32[] memory proof,
        bytes memory data
    ) payable public {
        require(wlStartTime != 0 && block.timestamp >= wlStartTime, "Whitelist not started yet!");
        require(
            MerkleProof.verify(
                proof,
                wlRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Only WhiteList accounts can use this function"
        );
        require(_balanceOf(msg.sender) + amount <= whitelistTokenPerPerson, "MADHS: Whitelist limit reached!");

        if (amount > 1) {
            uint256[] memory _ids = new uint[](amount);
            for (uint256 i = 0; i < amount; i++) {
                _ids[i] = 1;
            }
            _batch(msg.sender, _ids, _ids, data);
        } else {
            _doMint(msg.sender, amount, data);
        }
    }

    /**
     * @dev Minting function
     * Do minting for anyone, validates that public sales started
     * @param account wallet to send tokens
     * @param amount number of tokens to mint
     * @param data additional transaction data
     */
    function mint(address account, uint256 /* id */, uint256 amount, bytes memory data
    ) payable public {
        require(msg.sender == owner() || (publicStartTime != 0 && block.timestamp >= publicStartTime), "MADHS: Sales not started!");

        if (amount > 1) {
            uint256[] memory _ids = new uint[](amount);
            for (uint256 i = 0; i < amount; i++) {
                _ids[i] = 1;
            }
            _batch(msg.sender, _ids, _ids, data);
        } else {
            _doMint(account, amount, data);
        }
    }

    function _doMint(address account, uint256 amount, bytes memory data) internal {
        require(amount == 1, "MADHS: It is Non fungible token, can exists only one item!");
        require(_currentTokenID + amount <= maxTokens, "MADHS: Mint limit is reached");

        uint256 _price = getPrice();
        require(
            _price * amount <= msg.value,
            "MADHS: Ether value sent is not correct"
        );

        _mint(account, _getNextTokenID(), amount, data);
        transferAmount();
    }

    function mintBatch(
        address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data
    ) payable public {
        require(msg.sender == owner() || (publicStartTime != 0 && block.timestamp >= publicStartTime), "MADHS: Sales not started!");
        _batch(account, ids, amounts, data);
    }

    function getPrice() internal view returns (uint256) {
        uint256 _price = 0;
        if (msg.sender != owner()) {
            if (block.timestamp < publicStartTime) {
                _price = whitelistPrice;
            } else {
                _price = publicPrice;
            }
        }
        return _price;
    }

    function _batch(
        address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data
    ) internal {
        require(_currentTokenID + ids.length <= maxTokens, "MADHS: Mint limit is reached");

        uint256 _price = getPrice();
        require(
            _isOwnerOrProxy(msg.sender) || _price * ids.length <= msg.value,
            "Batch: Ether value sent is not correct"
        );

        uint256[] memory _ids = new uint[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i] == 1, "MADHS: It is Non fungible token, can exists only one item!");
            _ids[i] = _getNextTokenID();
        }

        _mintBatch(account, _ids, amounts, data);
        transferAmount();
    }

    function transferAmount() internal {
        if (msg.value > 0) {
            uint256 communityAmount = (msg.value * communityRate) / 10000;
            withdraw(communityWallet, communityAmount);
            withdraw(projectWallet, msg.value - communityAmount);
        }
    }

    /**
     * @dev Withdraw from contract amount of money to account
     * @param account Address where to send balance
     * @param amount Amount to send
     */
    function withdraw(address account, uint256 amount) internal {
        (bool success, /* bytes memory data */) = payable(account).call{value:amount}("");
        require(success, "Could not withdraw amount!");
    }

    function _isOwnerOrProxy(address _address) internal view returns (bool) {
        return owner() == _address ||
                address(proxyRegistryAddress) == _address;
    }

    /** @dev EIP2981 royalties */
    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        royaltyWallet = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyWallet, (_salePrice * royaltyRate) / 10000);
    }

    function setRoyaltyRate(uint256 rate) external onlyOwner {
        royaltyRate = rate;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, IERC165)
    returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /**
     * @dev Calculate total balance for tokens in collection, used to limit whitelist
     */
    function _balanceOf(address account) internal view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < _currentTokenID; i++) {
            balance = balance + balanceOf(account, i);
        }
        return balance;
    }

}