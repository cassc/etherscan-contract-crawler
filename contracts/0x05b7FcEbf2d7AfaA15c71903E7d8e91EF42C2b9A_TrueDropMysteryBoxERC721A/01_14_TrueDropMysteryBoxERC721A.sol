// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IDropManagementForERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./libraries/Verify.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TrueDropMysteryBoxERC721A is
    ERC721A,
    ERC2981,
    ReentrancyGuard,
    Ownable
{
    uint256 _maxSupply = 10000;
    uint256 _mintFee = 0;
    uint96 _royaltyFee = 500;
    string _name = "TrueDrop Mystery Box";
    string _symbol = "TRUEBOX";
    address _feeReceiver;
    string _contractURI;
    mapping(address => uint256) internal _minted;
    mapping(address => bool) _operators;
    mapping(address => uint256) internal _whitelist;
    event TrueDropMysteryBoxMinted(address owner, uint256 quantity);
    event TrueDropMysteryBoxUpdatedWhitelist(
        address[] addresses,
        uint256[] quantities
    );
    event TrueDropMysteryBoxAddWhitelist(
        address[] addresses,
        uint256[] quantities
    );
    event TrueDropMysteryBoxRemoveWhitelist(address[] addresses);

    constructor(
        address feeReceiver,
        string memory mContractURI,
        string memory baseURI
    ) payable ERC721A(_name, _symbol) {
        _contractURI = mContractURI;
        _feeReceiver = feeReceiver;
        _baseURI = baseURI;
        _setDefaultRoyalty(_feeReceiver, _royaltyFee);
    }

    modifier onlyOperator() {
        require(_operators[msg.sender], "Caller is not the operator");
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function isOperator(address userAddress) public view returns (bool) {
        return _operators[userAddress];
    }

    function setBaseUri(string memory uri) external onlyOwner {
        _baseURI = uri;
    }

    function setFeeReceiver(address feeReceiver) external onlyOwner {
        _feeReceiver = feeReceiver;
        //update ERC-2981
        _setDefaultRoyalty(_feeReceiver, _royaltyFee);
    }

    /// @notice This function is used to get current contractURI
    /// @dev This function is used to get current contractURI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /// @notice This function is used to get current maxSupply
    /// @dev This function is used to get current maxSupply
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /// @notice This function is allow owner set operator
    /// @dev This function is allow owner set operator
    /// @param operatorAddress address will be apply new update once executed
    /// @param value bool This value use to set or unset operator
    function setOperator(address operatorAddress, bool value)
        external
        onlyOwner
    {
        require(operatorAddress != address(0), "Address is zero address");
        require(_operators[operatorAddress] != value, "Already set");
        _operators[operatorAddress] = value;
    }

    /// @notice This function is allow owner set current mintFee
    /// @dev This function is allow owner set current mintFee
    /// @param mintFee uint256 new fee will be apply once executed
    function setMintFee(uint256 mintFee) external onlyOwner {
        _mintFee = mintFee;
    }

    /// @notice This function is used to get current mintFee
    /// @dev This function is used to get current mintFee
    function getMintFee() public view returns (uint256) {
        return _mintFee;
    }

    /// @notice This function allow operator set whitelist can mint for list users
    /// @dev This function allow operator set whitelist can mint for list users
    /// @param addresses array of address of users need to set or update
    /// @param quantities array of quantity need to set or update
    function modifyWhitelist(
        address[] memory addresses,
        uint256[] memory quantities
    ) external onlyOperator {
        require(addresses.length == quantities.length, "Not match length");
        for (uint256 i = 0; i < addresses.length; ++i) {
            require(_minted[addresses[i]] < quantities[i], "Quantity invalid");
            _whitelist[addresses[i]] = quantities[i];
        }
        emit TrueDropMysteryBoxUpdatedWhitelist(addresses, quantities);
    }

    /// @notice This function allow operator set whitelist can mint for list users
    /// @dev This function allow operator set whitelist can mint for list users
    /// @param addresses array of address of users need to set or update
    /// @param quantities array of quantity need to set or update
    function addWhitelist(
        address[] memory addresses,
        uint256[] memory quantities
    ) external onlyOperator {
        require(addresses.length == quantities.length, "Not match length");
        for (uint256 i = 0; i < addresses.length; ++i) {
            _whitelist[addresses[i]] += quantities[i];
        }
        emit TrueDropMysteryBoxAddWhitelist(addresses, quantities);
    }

    /// @notice This function allow operator set whitelist can mint for list users
    /// @dev This function allow operator set whitelist can mint for list users
    /// @param addresses array of address of users need to set or update
    function removeWhitelist(address[] memory addresses) external onlyOperator {
        require(addresses.length > 0, "No address need remove");
        for (uint256 i = 0; i < addresses.length; ++i) {
            _whitelist[addresses[i]] = _minted[addresses[i]];
        }
        emit TrueDropMysteryBoxRemoveWhitelist(addresses);
    }

    /// @notice This function is used to get current whitelist can mint, and minted quantity
    /// @dev This function is used to get current whitelist can mint, and minted quantity
    /// @param userAddress address of user need to check
    function getMintStat(address userAddress)
        public
        view
        returns (uint256, uint256)
    {
        return (_whitelist[userAddress], _minted[userAddress]);
    }

    /// @notice This function is used to mint NFT
    /// @dev This function is used to mint NFT
    /// @param quantity uint256 quantity of NFT will be minted once executed
    function mintNFT(uint256 quantity) external payable nonReentrant {
        require(_whitelist[msg.sender] > _minted[msg.sender], "Unauthorize");
        require(
            _whitelist[msg.sender] >= quantity + _minted[msg.sender],
            "Over limit"
        );
        require(totalSupply() + quantity <= _maxSupply, "Out of stock");
        if (_mintFee > 0) {
            require(
                transferFees(_feeReceiver, _mintFee * quantity),
                "Pay fee fail"
            );
        }
        _minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        emit TrueDropMysteryBoxMinted(msg.sender, quantity);
    }

    /// @notice This function is used internally for send the native tokens to other accounts
    /// @dev This function is used internally for send the the native tokens to other accounts
    /// @param to address is the address that will receive the _amount
    /// @param amount uint256 value involved in the deal
    /// @return true or false if the transfer worked out
    function transferFees(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        return success;
    }

    /// @notice This function allows the owner to set default royalties following EIP-2981 royalty standard.
    /// @dev This function allows the owner to set default royalties following EIP-2981 royalty standard.
    /// @param feeNumerator uint96 value of fee
    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        _royaltyFee = feeNumerator;
        _setDefaultRoyalty(_feeReceiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}