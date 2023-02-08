//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";

contract SupermetaStore is OwnableUpgradeable, ERC1155Upgradeable, RevokableDefaultOperatorFiltererUpgradeable {

    error InsufficientPaymentSent(uint256 __tokenId, uint256 __tokenAmount, uint256 __expectedPrice, uint256 __ETHSent);
    error ExcessivePaymentSent(uint256 __tokenId, uint256 __tokenAmount, uint256 __expectedPrice, uint256 __ETHSent);
    error ExceedingMintLimit(uint256 __tokenId, uint256 __limit);
    error NotOnSale(uint256 __tokenId);
    error NotController(address __controller);
    using StringsUpgradeable for uint256;

    event TokenMinted(uint256 indexed tokenId, uint256 indexed amountLeft, address indexed minter);

    mapping (uint256 => bool) public isTokenOnSale;
    mapping (address => bool) public isController;

    mapping (string => uint256) public databaseIdToTokenId;
    mapping (uint256 => string) public tokenIdToDatabaseId;

    mapping (uint256 => uint256) public tokenLimit;
    mapping (uint256 => uint256) public tokenPrice;

    mapping (uint256 => uint256) tokenCurrentSupply;

    string private baseTokenURI;
    uint256 public currentTokenId;

    uint256 public supermetaEarningsShare;
    uint256 public _0xytocinEarningsShare;

    address public supermetaAccount;
    address public _0xytocinAccount;

    modifier paymentCheck (uint256 _tokenId, uint256 _amount) {
        if (tokenPrice[_tokenId] * _amount > msg.value) {
            revert InsufficientPaymentSent(
            {
            __tokenId : _tokenId,
            __tokenAmount : _amount,
            __expectedPrice : tokenPrice[_tokenId] * _amount,
            __ETHSent : msg.value
            });
        }

        if (msg.value > tokenPrice[_tokenId] * _amount) {
            revert ExcessivePaymentSent(
            {
            __tokenId : _tokenId,
            __tokenAmount : _amount,
            __expectedPrice : tokenPrice[_tokenId] * _amount,
            __ETHSent : msg.value
            });
        }
        _;
    }

    modifier limitCheck (uint256 _tokenId, uint256 _amount) {
        if ( tokenLimit[_tokenId] < _amount) {
            revert ExceedingMintLimit(
            {
            __tokenId : _tokenId,
            __limit : tokenLimit[_tokenId]
            });
        }
        _;
    }

    modifier onlyController {
        if (!isController[msg.sender]) {
            revert NotController(msg.sender);
        }
        _;
    }

    function mint(address _account, uint256 _id, uint256 _amount) external payable paymentCheck(_id, _amount) limitCheck(_id, _amount) {
        if (!isTokenOnSale[_id]) {
            revert NotOnSale(
            {
            __tokenId : _id
            });
        }
        tokenLimit[_id] -= _amount;
        tokenCurrentSupply[_id] += _amount;
        disburseEarning(msg.value);
        _mint(_account, _id, _amount, "");
        emit TokenMinted(_id, tokenLimit[_id], msg.sender);
    }

    function addOrModifyTokenSpecs (uint256 _priceOfToken, uint256 _tokenLimit, uint256 _tokenId, string calldata _dataBaseId) external onlyController {
        if (!isTokenOnSale[_tokenId]) {
            uint256 tokenId = currentTokenId+=1;
            isTokenOnSale[tokenId] = true;
            tokenLimit[tokenId] = _tokenLimit;
            tokenPrice[tokenId] = _priceOfToken;
            tokenIdToDatabaseId[tokenId] = _dataBaseId;
            databaseIdToTokenId[_dataBaseId] = tokenId;
        } else {
            tokenLimit[_tokenId] = _tokenLimit;
            tokenPrice[_tokenId] = _priceOfToken;
            tokenIdToDatabaseId[_tokenId] = _dataBaseId;
            databaseIdToTokenId[_dataBaseId] = _tokenId;
        }
    }

    function burn(uint256 id, uint256 amount) external {
        tokenCurrentSupply[id] -= amount;
        _burn(msg.sender, id, amount);
    }

    function modifyDatabaseId (uint256 _tokenId, string memory _databaseId) public onlyController {
        tokenIdToDatabaseId[_tokenId] = _databaseId;
    }

    function modifyTokenId (string memory _databaseId, uint256 _tokenId) public onlyController {
        databaseIdToTokenId[_databaseId] = _tokenId;
    }

    /// @notice User should pass the values by multiplying them with 100; Eg: if I have to pass
    /// @notice 13%, I would write 1300, 20% would be 2000, 50% would be 5000, 12.75% would be 1275
    function modifyEarningsShares (uint256 _supermetaShare, uint256 __0xytocinShare) external onlyController {
        supermetaEarningsShare = _supermetaShare;
        _0xytocinEarningsShare = __0xytocinShare;
    }

    function modifyTeamAccounts (address _supermetaAccount, address __0xytocinAccount) external onlyController {
        supermetaAccount = _supermetaAccount;
        _0xytocinAccount = __0xytocinAccount;
    }


    function disburseEarning(uint256 _amount) private {
        uint256 _supermetaShare = (_amount * supermetaEarningsShare)/10000;
        uint256 __0xytocinShare = (_amount * _0xytocinEarningsShare)/10000;

        payable(supermetaAccount).transfer(_supermetaShare);
        payable(_0xytocinAccount).transfer(__0xytocinShare);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function toggleControllerStatus (address[] memory _controllers) external onlyOwner {
        for (uint256 i = 0; i < _controllers.length; i++) {
            isController[_controllers[i]] = !isController[_controllers[i]];
        }
    }

    function mintTokens(address _to, uint256 _id, uint256 _amount) external onlyController {
        _mint(_to, _id, _amount, "");
    }

    function initialize (string memory _tokenURI, address _superMetaAddress, address _0xyAddress) public initializer {
        __Ownable_init();
        __ERC1155_init(_tokenURI);
        __RevokableDefaultOperatorFilterer_init();
        baseTokenURI = _tokenURI;
        supermetaEarningsShare = 9500;
        _0xytocinEarningsShare = 500;
        supermetaAccount = _superMetaAddress;
        _0xytocinAccount = _0xyAddress;
    }

    function uri(uint256 _tokenID) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, tokenIdToDatabaseId[_tokenID]));
    }

    function getBaseTokenURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function totalTokensInStore() public view returns (uint256) {
        return currentTokenId;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function owner()
    public
    view
    virtual
    override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
    returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function currentSupplyOfToken(uint256 _tokenId) external view returns (uint256) {
        return tokenCurrentSupply[_tokenId];
    }
}