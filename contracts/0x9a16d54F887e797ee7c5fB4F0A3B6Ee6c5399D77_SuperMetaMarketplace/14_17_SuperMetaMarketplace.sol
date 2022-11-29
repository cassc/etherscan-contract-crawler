//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./upgradeable/RevokableDefaultOperatorFiltererUpgradeable.sol";
contract SuperMetaMarketplace is OwnableUpgradeable, ERC1155Upgradeable, RevokableDefaultOperatorFiltererUpgradeable {

    error Token__Staked(uint256 __tokenId);
    error Not_Enough_Tokens(uint256 __tokenId, uint256 __amount);
    error Insufficient_Balance(uint256 __tokenId, uint256 __amount, uint256 __expectedPrice, uint256 __amountSent);
    error Balance_Overflow(uint256 __tokenId, uint256 __amount, uint256 __expectedPrice, uint256 __amountSent);
    error Mint_Limit_Reached(uint256 __tokenId, uint256 __limit);
    error Non_Existing_Token(uint256 __tokenId);
    error Not_Controller(address __controller);

    using StringsUpgradeable for uint256;

    mapping (uint256 => bool) private whitelistedTokenId;
    mapping (uint256 => bool) public isStaked;
    mapping (uint256 => uint256) private tokenIdToImageId;
    mapping (uint256 => uint256) private tokenLimit;
    mapping (uint256 => uint256) private tokenPrice;
    mapping (uint256 => uint256) private stakingRequirement;
    mapping (address => bool) public isController;
    mapping (uint256 => address) public tokenIdToArtistWallet;
    string private baseTokenURI;
    uint256 public currentTokenId;
    uint256 public artistProfitPercentage;
    uint256 public superMetaProfitPercentage;
    uint256 public oxytocinProfitPercentage;
    address public superMetaAddress;
    address public oxytocinAddress;

    modifier paymentCheck (uint256 _tokenId, uint256 _amount) {
        if (tokenPrice[_tokenId] * _amount > msg.value) {
            revert Insufficient_Balance(
            {
            __tokenId : _tokenId,
            __amount : _amount,
            __expectedPrice : tokenPrice[_tokenId] * _amount,
            __amountSent : msg.value
            });
        }

        if (msg.value > tokenPrice[_tokenId] * _amount) {
            revert Balance_Overflow(
            {
            __tokenId : _tokenId,
            __amount : _amount,
            __expectedPrice : tokenPrice[_tokenId] * _amount,
            __amountSent : msg.value
            });
        }
        _;
    }

    modifier limitCheck (uint256 _tokenId, uint256 _amount) {
        if ( tokenLimit[_tokenId] < _amount) {
            revert Mint_Limit_Reached(
            {
            __tokenId : _tokenId,
            __limit : tokenLimit[_tokenId]
            });
        }
        _;
    }

    modifier onlyController {
        if (!isController[msg.sender]) {
            revert Not_Controller(msg.sender);
        }
        _;
    }

    function mint(address _account, uint256 _id, uint256 _amount) external payable paymentCheck(_id, _amount) limitCheck(_id, _amount) {
        if (!whitelistedTokenId[_id]) {
            revert Non_Existing_Token(
            {
            __tokenId : _id
            });
        }
        tokenLimit[_id] -= _amount;
        distributeETH(msg.value, tokenIdToArtistWallet[_id]);
        _mint(_account, _id, _amount, "");
    }

    function toggleStakeStatus (uint256 _tokenId) external {
        if (stakingRequirement[_tokenId] > balanceOf(msg.sender, _tokenId)) {
            revert Not_Enough_Tokens(
            {
            __tokenId : _tokenId,
            __amount : stakingRequirement[_tokenId]
            });
        }
        isStaked[_tokenId] = !isStaked[_tokenId];
    }

    function whitelistTokenId (uint256 _priceOfToken, uint256 _tokenLimit, uint256 _projectId, address _artist) external onlyController {
        uint256 tokenId = currentTokenId+=1;
        whitelistedTokenId[tokenId] = true;
        tokenLimit[tokenId] = _tokenLimit;
        tokenPrice[tokenId] = _priceOfToken;
        tokenIdToImageId[tokenId] = _projectId;
        tokenIdToArtistWallet[tokenId] = _artist;
        currentTokenId += 1;
    }

    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    function setStakingRequirement (uint256 _tokenId, uint256 _amount) external onlyController {
        stakingRequirement[_tokenId] = _amount;
    }

    function changeImageId (uint256 _tokenId, uint256 _projectId) public onlyController {
        tokenIdToImageId[_tokenId] = _projectId;
    }

    function setProfitRatios (uint256 _artistCut, uint256 _superMetaCut, uint256 _oxytocinCut) external onlyController {
        artistProfitPercentage = _artistCut;
        superMetaProfitPercentage = _superMetaCut;
        oxytocinProfitPercentage = _oxytocinCut;
    }

    function setAddresses (address _superMetaAddress, address _oxytocinAddress) external onlyController {
        superMetaAddress = _superMetaAddress;
        oxytocinAddress = _oxytocinAddress;
    }

    function registerAddressToOperatorFilter (address _addressToBeRegistered) external {
        operatorFilterRegistry.register(_addressToBeRegistered);
    }

    function registerAndSubscribeAddressToOperatorFilter ( address _addressToBeRegistered, address _registryToCopy ) external {
        operatorFilterRegistry.registerAndSubscribe( _addressToBeRegistered, _registryToCopy );
    }

    function distributeETH(uint256 _amount, address _artistAddress) private {
        uint256 _amountToArtist = (_amount * artistProfitPercentage)/100;
        uint256 _amountToOwner = (_amount * superMetaProfitPercentage)/100;
        uint256 _amountTo0xy = (_amount * oxytocinProfitPercentage)/100;
        payable(superMetaAddress).transfer(_amountToOwner);
        payable(oxytocinAddress).transfer(_amountTo0xy);
        payable(_artistAddress).transfer(_amountToArtist);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }



    function setControllers (address[] memory _controllers) external onlyOwner {
        for (uint256 i = 0; i < _controllers.length; i++) {
            isController[_controllers[i]] = true;
        }
    }

    function initialize (string memory _tokenURI, address _superMetaAddress, address _oxyAddress) public initializer {
        __Ownable_init();
        __ERC1155_init(_tokenURI);
        __RevokableDefaultOperatorFilterer_init();
        baseTokenURI = _tokenURI;
        artistProfitPercentage = 85;
        superMetaProfitPercentage = 10;
        oxytocinProfitPercentage = 5;
        superMetaAddress = _superMetaAddress;
        oxytocinAddress = _oxyAddress;
    }

    function uri(uint256 _tokenID) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, tokenIdToImageId[_tokenID].toString()));
    }

    function getBaseTokenURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        if (isStaked[tokenId]) {
            revert Token__Staked(
                {
                __tokenId : tokenId
                });
        }
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
}