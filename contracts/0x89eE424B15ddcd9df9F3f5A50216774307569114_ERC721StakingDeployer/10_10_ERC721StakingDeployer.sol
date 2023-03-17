// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ERC721VaultFactory {
    function deploy(
        bool _softStaking,
        bool _hardStaking,
        address _owner
    ) external virtual returns (address);
}

abstract contract ERC721RewardsFactory {
    function deploy(
        address _vaultAddress,
        address _owner
    ) external virtual returns (address);
}

abstract contract ERC20Factory {
    function deploy(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _owner
    ) external virtual returns (address);
}

abstract contract ERC721StakingVault {
    function setContracts(address _erc20Contract, address _rewardContract) external virtual;
}

abstract contract ERC721StakingRewards {
    function addCollections(address[] memory _contracts, uint72[] memory _softRates, uint72[] memory _hardRates) external virtual;
}

contract ERC721StakingDeployer is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    struct TokenParams {
        string name;
        string symbol;
        uint256 maxSupply;
    }

    struct VaultParams {
       bool softStaking;
       bool hardStaking;
    }

    struct RewardParams {
       address[] collections;
       uint72[] softRates;
       uint72[] hardRates;
    }

    mapping(uint256 => address) public deployments;
    mapping(uint256 => uint256) public discounts;
    address public erc20Deployer;
    address public vaultDeployer;
    address public rewardDeployer;
    address public launchpassAddress;
    address payable public treasuryAddress;
    uint256 public price;
    address[] private contracts;
    IERC20 public usdc;

    constructor(
        address _launchpassAddress, 
        address payable _treasuryAddress, 
        address _usdcAddress
    ) {
        launchpassAddress = _launchpassAddress;
        treasuryAddress = _treasuryAddress;
        usdc = IERC20(_usdcAddress);
    }

    function getDeployments() external view returns (address[] memory) {
        return contracts;
    }

    function setDiscount(uint256 _launchpassId, uint16 _basisPoints) external onlyOwner {
        require(_basisPoints >= 0 && _basisPoints <= 10000, "Invalid discount");
        if (_basisPoints > 0) {
            discounts[_launchpassId] = _basisPoints;
        } else {
            delete discounts[_launchpassId];
        }
    }

    function getPrice(uint256 _launchpassId) public view returns (uint256) {
        return price - (price * discounts[_launchpassId]/10000);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price * (10**18);
    }

    function deleteDeployment(uint256 _launchpassId) external onlyOwner {
        delete deployments[_launchpassId];
    }

    function setUSDC(address _contract) external onlyOwner {
        usdc = IERC20(_contract);
    }

    function updateLaunchpassAddress(address _launchpassAddress) external onlyOwner {
        launchpassAddress = _launchpassAddress;
    }

    function updateTreasuryAddress(address payable _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function updateDeployers(address _erc20Deployer, address _vaultDeployer, address _rewardDeployer) external onlyOwner {
        erc20Deployer = _erc20Deployer;
        vaultDeployer = _vaultDeployer;
        rewardDeployer = _rewardDeployer;
    }

    function deploy(
        uint256 _launchpassId,
        TokenParams memory _tokenParams,
        VaultParams memory _vaultParams,
        RewardParams memory _rewardParams
    ) external nonReentrant {
        require(IERC721(launchpassAddress).ownerOf(_launchpassId) == msg.sender,  "Not owner");
        require(deployments[_launchpassId] == address(0),  "Already deployed");
        uint256 _price = getPrice(_launchpassId);
        if (_price > 0) {
            require(_price <= usdc.balanceOf(msg.sender), "Insufficient funds.");
            usdc.safeTransferFrom(msg.sender, treasuryAddress, _price);
        }

        // deploy contracts
        address _erc20Contract = ERC20Factory(erc20Deployer).deploy(_tokenParams.name, _tokenParams.symbol, _tokenParams.maxSupply * (10 ** 18), msg.sender);
        address _vaultContract = ERC721VaultFactory(vaultDeployer).deploy(_vaultParams.softStaking, _vaultParams.hardStaking, address(this));
        address _rewardContract = ERC721RewardsFactory(rewardDeployer).deploy(_vaultContract, address(this));

        // configure contracts
        require(_rewardParams.collections.length > 0, "Bad parameters");
        require(_rewardParams.collections.length == _rewardParams.softRates.length, "Bad parameters");
        require(_rewardParams.collections.length == _rewardParams.hardRates.length, "Bad parameters");
        ERC721StakingVault(_vaultContract).setContracts(_erc20Contract, _rewardContract);
        ERC721StakingRewards(_rewardContract).addCollections(_rewardParams.collections, _rewardParams.softRates, _rewardParams.hardRates);

        // transfer ownership
        Ownable(_vaultContract).transferOwnership(msg.sender);
        Ownable(_rewardContract).transferOwnership(msg.sender);

        // log deployments
        deployments[_launchpassId] = address(_rewardContract);
        contracts.push(_rewardContract);
        if (discounts[_launchpassId] > 0) delete discounts[_launchpassId];
    }

    function withdraw(uint256 _amount, address _contract) public onlyOwner {
        require(IERC20(_contract).balanceOf(address(this)) >= _amount, "Insufficient balance");
        IERC20(_contract).transfer(msg.sender, _amount);
    }
}