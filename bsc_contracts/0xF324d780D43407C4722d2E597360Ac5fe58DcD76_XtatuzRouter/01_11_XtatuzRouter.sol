// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IXtatuzFactory.sol";
import "../interfaces/IXtatuzProject.sol";
import "../interfaces/IPresaled.sol";
import "../interfaces/IProperty.sol";
import "../interfaces/IXtatuzPricing.sol";
import "../interfaces/IXtatuzReroll.sol";

contract XtatuzRouter {
    using Counters for Counters.Counter;
    Counters.Counter private _projectIdCounter;

    IXtatuzFactory private _xtatuzFactory;

    address private _spvAddress;
    address private _xtatuzFactoryAddress;
    address private _membershipAddress;
    address public xtaTokenAddress;
    address private _pricingAddress;
    address private _rerollAddress;

    uint256 public triggerPeriod = 52 weeks;

    enum CollectionType {
        PRESALE,
        INCOMPLETE,
        COMPLETE
    }

    struct Collection {
        address contractAddress;
        uint256[] tokenIdList;
        CollectionType collectionType;
    }

    mapping(address => uint256[]) private _memberdProject;
    mapping(string => mapping(uint256 => uint256)) public referralPerProject; 
    mapping(address => mapping(uint256 => bool)) private _isMemberClaimed;
    mapping(address => mapping(uint256 => uint256)) private _triggerTimestamp;
    mapping(uint256 => uint256) private _totalRerollFee;

    constructor(
        address spv_,
        address factoryAddress_,
        address xtaTokenAddress_
    ) {
        _transferSpv(spv_);
        _xtatuzFactory = IXtatuzFactory(factoryAddress_);
        xtaTokenAddress = xtaTokenAddress_;
        _projectIdCounter.increment();
    }

    event SpvTransferred(address indexed prevSpv, address indexed newSpv);
    event CreatedProject(uint256 indexed projectId, address indexed projectAddress);
    event AddProjectMember(uint256 indexed projectId, address indexed member, string indexed referral, uint256 totalPrice);
    event Claimed(uint256 indexed projectId, address member);
    event Refunded(uint256 indexed projectId, address member);
    event Trigger(uint256 indexed projectId, address member, uint256 timestamp);
    event Buyback(uint256 indexed projectId, address member);
    event ChangePropertyStatus(uint256 indexed projectId, IProperty.PropertyStatus status);
    event NFTReroll(address indexed member, uint256 projectId, uint256 tokenId);
    event ClaimedRerollFee(address indexed spv, uint256 projectId, uint256 amount);

    modifier onlySpv() {
        require(_spvAddress == msg.sender, "ROUTER: ONLY_SPV");
        _;
    }

    modifier prohibitZeroAddress(address caller) {
        require(caller != address(0), "ROUTER: ADDRESS_0");
        _;
    }

    function createProject(
        uint256 count_,
        address tokenAddress_,
        string memory name_,
        string memory symbol_,
        uint256 startPresale_,
        uint256 endPresale_,
        IProperty.PackageDetail[] memory packages_
    ) public onlySpv {
        uint256 projectId = _projectIdCounter.current();
        require(startPresale_ >= block.timestamp - 1000, "ROUTER: INVALID_START_DATE");
        require(endPresale_ > startPresale_, "ROUTER: INVALID_END_DATE");

        uint256 totalSupply = IERC20(tokenAddress_).totalSupply();
        require(totalSupply > 0, "ROUTER: INVALID_TOKEN");

        _projectIdCounter.increment();
        IXtatuzFactory.ProjectPrepareData memory data = IXtatuzFactory.ProjectPrepareData({
            projectId_: projectId,
            spv_: msg.sender,
            trustee_: msg.sender,
            count_: count_,
            tokenAddress_: tokenAddress_,
            membershipAddress_: _membershipAddress,
            name_: name_,
            symbol_: symbol_,
            packages_: packages_,
            routerAddress: address(this)
        });

        address projectAddress = _xtatuzFactory.createProjectContract(data);
        IXtatuzProject(projectAddress).setPresalePeriod(startPresale_, endPresale_);
        emit CreatedProject(projectId, projectAddress);
    }

    function addProjectMember(
        uint256 projectId_,
        uint256 package_,
        uint256 amount_,
        string memory referral_
    ) public {
        address projectAddress = _xtatuzFactory.getProjectAddress(projectId_);
        IXtatuzProject project = IXtatuzProject(projectAddress);
        uint256 price = project.addProjectMember(msg.sender, package_, amount_);

        uint256 minPrice = project.minPrice();
        uint256 refAmount = (price - (amount_ * minPrice));
        referralPerProject[referral_][projectId_] += refAmount;

        address tokenAddress = project.tokenAddress();
        IERC20(tokenAddress).transferFrom(msg.sender, projectAddress, price);

        uint256[] memory memberedProject = _memberdProject[msg.sender];
        bool foundedIndex;
        for (uint256 index = 0; index < memberedProject.length; index++) {
            if (memberedProject[index] == projectId_) {
                foundedIndex = true;
            }
        }
        if (!foundedIndex) {
            _memberdProject[msg.sender].push(projectId_);
        }

        _isMemberClaimed[msg.sender][projectId_] = false;
        emit AddProjectMember(projectId_, msg.sender, referral_, price);
    }

    function claim(uint256 projectId_) public {
        address projectAddress = _xtatuzFactory.getProjectAddress(projectId_);

        IXtatuzProject(projectAddress).claim(msg.sender);

        _isMemberClaimed[msg.sender][projectId_] = true;
        _triggerTimestamp[msg.sender][projectId_] = block.timestamp;

        emit Claimed(projectId_, msg.sender);
    }

    function refund(uint256 projectId_) public {
        uint256[] memory memberedProject = _memberdProject[msg.sender];
        address projectAddress = _xtatuzFactory.getProjectAddress(projectId_);

        

        int256 foundedIndex = -1;
        for (uint256 index = 0; index < memberedProject.length; index++) {
            if (memberedProject[index] == projectId_) {
                foundedIndex = int256(index);
            }
        }
        if (foundedIndex > -1) {
            delete _memberdProject[msg.sender][uint256(foundedIndex)];
        }

        IXtatuzProject(projectAddress).refund(msg.sender);

        emit Refunded(projectId_, msg.sender);
    }

    function nftReroll(uint256 projectId_, uint256 tokenId_) public {
        require(_rerollAddress != address(0), "ROUTER: NO_REROLL_ADDRESS");

        address propertyAddress = _xtatuzFactory.getPropertyAddress(projectId_);
        IProperty property = IProperty(propertyAddress);
        IXtatuzReroll rerollContract = IXtatuzReroll(_rerollAddress);

        string memory prevUri = property.tokenURI(tokenId_);
        uint256 fee = rerollContract.rerollFee();
        string[] memory rerollData = rerollContract.getRerollData(projectId_);        
        address tokenOwner = property.ownerOf(tokenId_);
        require(tokenOwner == msg.sender, "ROUTER: NOT_NFT_OWNER");

        uint256 newIndex = block.timestamp % rerollData.length;
        property.setTokenURI(tokenId_, rerollData[newIndex]);
        rerollData[newIndex] = prevUri;
        rerollContract.setRerollData(projectId_, rerollData);

        IERC20(xtaTokenAddress).transferFrom(msg.sender, address(this), fee);
        _totalRerollFee[projectId_] += fee;

        emit NFTReroll(msg.sender, projectId_, tokenId_);
    }

    function claimRerollFee(uint256 projectId_) public onlySpv {
        require(_totalRerollFee[projectId_] > 0, "ROUTER: OUT_OF_FEE");
        uint256 totalFee = _totalRerollFee[projectId_];
        IERC20(xtaTokenAddress).transfer(msg.sender, totalFee);
        _totalRerollFee[projectId_] = 0;
        emit ClaimedRerollFee(msg.sender, projectId_, totalFee);
    }

    function trigger(uint256 projectId_) public {
        uint256[] memory memberedProject = _memberdProject[msg.sender];
        int256 foundedIndex = -1;
        for (uint256 index = 0; index < memberedProject.length; index++) {
            if (memberedProject[index] == projectId_) {
                foundedIndex = int256(index);
            }
        }
        require(foundedIndex > -1, "PROJECT: NOT_MEMBERED");
        _triggerTimestamp[msg.sender][projectId_] = block.timestamp;

        emit Trigger(projectId_, msg.sender, _triggerTimestamp[msg.sender][projectId_]);
    }

    function buyBack(
        address member_,
        uint256 projectId_,
        uint256 tokenId_
    ) public onlySpv {
        require(_isMemberClaimed[member_][projectId_], "PROJECT: DID_NOT_CLAIMED");

        uint256 lastTrigger = _triggerTimestamp[member_][projectId_] = block.timestamp;
        require(block.timestamp > (lastTrigger + triggerPeriod), "ROUTER: IN_PERIOD");

        address propertyAddress = _xtatuzFactory.getPropertyAddress(projectId_);
        address projectAddress = _xtatuzFactory.getProjectAddress(projectId_);

        IProperty property = IProperty(propertyAddress);
        IXtatuzProject project = IXtatuzProject(projectAddress);

        uint256 marketPrice = IXtatuzPricing(_pricingAddress).marketPrice(propertyAddress, tokenId_);
        property.transferFrom(member_, _spvAddress, tokenId_);

        address tokenAddress = project.tokenAddress();
        IERC20(tokenAddress).transfer(member_, marketPrice);

        emit Buyback(projectId_, member_);
    }

    function getProjectAddressById(uint256 projectId) public view returns (address) {
        return _xtatuzFactory.getProjectAddress(projectId);
    }

    function getAllCollection() public view returns (Collection[] memory) {
        uint256[] memory projectList = _memberdProject[msg.sender];
        Collection[] memory collections = new Collection[](projectList.length);
        for (uint256 index = 0; index < projectList.length; index++) {
            if (projectList[index] > 0) {
                uint256 projectId = projectList[index];
                address projectAddress = _xtatuzFactory.getProjectAddress(projectId);
                IXtatuzProject.Status status = IXtatuzProject(projectAddress).projectStatus();
                if (status == IXtatuzProject.Status.FINISH && _isMemberClaimed[msg.sender][projectId]) {
                    address propertyAddress = _xtatuzFactory.getPropertyAddress(projectId);
                    uint256[] memory tokenList = IProperty(propertyAddress).getTokenIdList(msg.sender);
                    IProperty.PropertyStatus propStatus = IProperty(propertyAddress).propertyStatus();
                    CollectionType collecType = CollectionType(uint256(propStatus) + 1);
                    Collection memory collect = Collection({
                        contractAddress: propertyAddress,
                        tokenIdList: tokenList,
                        collectionType: collecType
                    });
                    collections[index] = collect;
                } else {
                    address presaledAddress = _xtatuzFactory.getPresaledAddress(projectId);
                    uint256[] memory tokenList = IPresaled(presaledAddress).getPresaledOwner(msg.sender);
                    Collection memory collect = Collection({
                        contractAddress: presaledAddress,
                        tokenIdList: tokenList,
                        collectionType: CollectionType.PRESALE
                    });
                    collections[index] = collect;
                }
            }
        }
        return collections;
    }

    function setRerollAddress(address rerollAddress_) public prohibitZeroAddress(rerollAddress_) onlySpv {
        _rerollAddress = rerollAddress_;
    }

    function setMembershipAddress(address membershipAddress_) public prohibitZeroAddress(membershipAddress_) onlySpv {
        _membershipAddress = membershipAddress_;
    }

    function setXtaTokenAddress(address xtaTokenAddress_) public prohibitZeroAddress(xtaTokenAddress_) onlySpv {
        xtaTokenAddress = xtaTokenAddress_;
    }

    function setPricingAddress(address pricingAddress_) public prohibitZeroAddress(pricingAddress_) onlySpv {
        _pricingAddress = pricingAddress_;
    }

    function setTriggerPeriod(uint256 period_) public onlySpv {
        triggerPeriod = period_;
    }

    function setPropertyStatus(uint256 projectId_, IProperty.PropertyStatus status) public onlySpv {
        address propertyAddress = _xtatuzFactory.getPropertyAddress(projectId_);
        IProperty(propertyAddress).setPropertyStatus(status);
        emit ChangePropertyStatus(projectId_, status);
    }

    function _transferSpv(address newSpv_) internal prohibitZeroAddress(newSpv_) {
        address prevSpv = _spvAddress;
        _spvAddress = newSpv_;
        emit SpvTransferred(prevSpv, newSpv_);
    }
}