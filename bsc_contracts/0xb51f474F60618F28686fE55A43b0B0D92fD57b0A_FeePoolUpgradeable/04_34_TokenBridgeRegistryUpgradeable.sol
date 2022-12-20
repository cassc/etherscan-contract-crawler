// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./TokenUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./RegistryStorage.sol";
import "./FeePoolUpgradeable.sol";

contract TokenBridgeRegistryUpgradeable is Initializable, OwnableUpgradeable, RegistryStorage {

    address public bridgeUpgradeable;
    address public feePoolUpgradeable;

    event BridgeEnabled();
    event BridgeDisabled();

    event BridgeAdded(
        string tokenTicker,
        string tokenName,
        string imageUrl
    );

    event BridgeRemoved(
        string tokenTicker
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    function updateBridgeAddress(address _newBridgeAddress) external onlyOwner {
        require(_newBridgeAddress != address(0), "INVALID_BRIDGE");
        bridgeUpgradeable = _newBridgeAddress;
    }

    function updateFeePoolAddress(address _newFeePoolAddress) external onlyOwner {
        require(_newFeePoolAddress != address(0), "INVALID_FEEPOOL");
        feePoolUpgradeable = _newFeePoolAddress;
    }

    function deployChildToken(
        string calldata _name, 
        string calldata _imageUrl, 
        string calldata _ticker,
        uint8 _decimals
    ) public onlyOwner {
        require(bridgeTokenMetadata[_ticker].tokenAddress == address(0), "TOKEN_ALREADY_EXISTS");
        TokenUpgradeable newChildToken = new TokenUpgradeable();
        // newChildToken.initialize(_name, _ticker, _decimals, _msgSender());
        
        // deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        bytes memory data = abi.encodeWithSignature("initialize(string,string,uint8,address)", 
                                _name, _ticker, _decimals, _msgSender());
        // deploy TransparentUpgradeableProxy contract
        TransparentUpgradeableProxy transparentUpgradeableProxy = new TransparentUpgradeableProxy(address(newChildToken), address(proxyAdmin), data);
        
        // transfer ownership of token to bridge
        newChildToken = TokenUpgradeable(address(transparentUpgradeableProxy));
        newChildToken.transferOwnership(bridgeUpgradeable);
        // transfer ProxyAdmin ownership to the msg.sender so as to upgrade in future if reqd. 
        proxyAdmin.transferOwnership(_msgSender());

        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: _name,
            imageUrl: _imageUrl,
            tokenAddress: address(transparentUpgradeableProxy)
        });
        bridgeTokenMetadata[_ticker] = newBridgeTokenMetadata;
    }

    function addTokenMetadata(
        address _tokenAddress, 
        string calldata _imageUrl
    ) public onlyOwner {
        TokenUpgradeable token = TokenUpgradeable(_tokenAddress);

        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: token.name(),
            imageUrl: _imageUrl,
            tokenAddress: _tokenAddress
        });
        bridgeTokenMetadata[token.symbol()] = newBridgeTokenMetadata;
    }

    // function getTokenMetadata(string calldata tokenTicker) public view returns (BridgeTokenMetadata memory) {
    //     return bridgeTokenMetadata[tokenTicker];
    // }

    function addBridge(
        uint8 _bridgeType,
        string memory _tokenTicker,
        uint256 _epochLength,
        uint8 _feeType,
        uint256 _feeInBips
    ) public onlyOwner {
        BridgeTokenMetadata memory token = bridgeTokenMetadata[_tokenTicker];
        // address tokenAddress = bridgeTokenMetadata[_tokenTicker].tokenAddress;
        require(token.tokenAddress != address(0), "TOKEN_NOT_EXISTS");
        require(tokenBridge[_tokenTicker].startBlock == 0, "TOKEN_BRIDGE_ALREADY_EXISTS");
        require(_bridgeType == 0 || _bridgeType == 1, "INVALID_BRIDGE_TYPE");
        require(_feeType == 0 || _feeType == 1, "INVALID_FEE_TYPE");
        if(_bridgeType == 1) {
            TokenUpgradeable tokenInstance = TokenUpgradeable(token.tokenAddress);
            require(tokenInstance.owner() == bridgeUpgradeable, "BRIDGE_NOT_OWNER");
        }

        // add mapping to bridge
        // if(_feeType == 1) {
        //     _feeInBips *= 100;
        // }
        FeeConfig memory feeConfig = FeeConfig({
            feeType: _feeType,
            feeInBips: _feeInBips
        });
        TokenBridge memory newTokenBridge = TokenBridge({
            bridgeType: _bridgeType,
            tokenTicker: _tokenTicker,
            startBlock: block.number,
            epochLength: _epochLength,
            fee: feeConfig,
            // totalFeeCollected: 0,
            // totalActiveLiquidity: 0,
            noOfDepositors: 0,
            isActive: true
        });
        tokenBridge[_tokenTicker] = newTokenBridge;
        tokenBridges.push(_tokenTicker);

        // deploy setu version of token
        TokenUpgradeable primaryToken = TokenUpgradeable(bridgeTokenMetadata[_tokenTicker].tokenAddress);
        _deploySetuToken(token.name, _tokenTicker, primaryToken.decimals());

        BridgeUpgradeable(payable(bridgeUpgradeable)).initNextEpochBlock(_tokenTicker, _epochLength);
        
        emit BridgeAdded(_tokenTicker, bridgeTokenMetadata[_tokenTicker].name, bridgeTokenMetadata[_tokenTicker].imageUrl);
    }

    function _deploySetuToken(
        string memory _name, 
        string memory _ticker,
        uint8 _decimals
    ) internal {
        TokenUpgradeable setuToken = new TokenUpgradeable();
        // setuToken.initialize(_concatenate("setu", _name), _concatenate("setu", _ticker), _decimals, _msgSender());

        // deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        bytes memory data = abi.encodeWithSignature("initialize(string,string,uint8,address)", 
                                _concatenate("setu", _name), _concatenate("setu", _ticker), _decimals, _msgSender());
        // deploy TransparentUpgradeableProxy contract
        TransparentUpgradeableProxy transparentUpgradeableProxy = new TransparentUpgradeableProxy(address(setuToken), address(proxyAdmin), data);

        // transfer ownership of setu token to bridge
        setuToken = TokenUpgradeable(address(transparentUpgradeableProxy));
        setuToken.transferOwnership(bridgeUpgradeable);
        // transfer ProxyAdmin ownership to the msg.sender so as to upgrade in future if reqd. 
        proxyAdmin.transferOwnership(_msgSender());

        // Add to TokenBridge mapping
        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: _concatenate("setu", _name),
            imageUrl: "",
            tokenAddress: address(transparentUpgradeableProxy)
        });
        bridgeTokenMetadata[_concatenate("setu", _ticker)] = newBridgeTokenMetadata;
    }

    function _concatenate(
        string memory a, 
        string memory b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function updateFeeConfig(
        string calldata _tokenTicker,
        uint8 _feeType,
        uint256 _feeInBips
    ) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        require(FeePoolUpgradeable(payable(feePoolUpgradeable)).totalFees(_tokenTicker) == 0, "FEE_PRESENT");
        require(_feeType == 0 || _feeType == 1, "INVALID_FEE_TYPE");
        require(_feeInBips > 0, "ZERO_FEE");
        // if(_feeType == 1) {
        //     _feeInBips *= 100;
        // }
        FeeConfig memory feeConfig = FeeConfig({
            feeType: _feeType,
            feeInBips: _feeInBips
        });
        tokenBridge[_tokenTicker].fee = feeConfig;
    }

    function updateEpochLength(
        string calldata _tokenTicker,
        uint256 _newEpochLength
    ) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        require(_newEpochLength > 0, "ZERO_EPOCH_LENGTH");
        tokenBridge[_tokenTicker].epochLength = _newEpochLength;
    }

    function disableBridgeToken(string calldata _tokenTicker) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        tokenBridge[_tokenTicker].isActive = false;
    }

    function enableBridgeToken(string calldata _tokenTicker) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        tokenBridge[_tokenTicker].isActive = true;
    }

    function disableBridge() public onlyOwner {
        isBridgeActive = false;
        emit BridgeDisabled();
    }

    function enableBridge() public onlyOwner {
        isBridgeActive = true;
        emit BridgeEnabled();
    }

    // function getFeeAndLiquidity(string calldata _tokenTicker) public view returns (uint256, uint256) {
    //     return (tokenBridge[_tokenTicker].totalFeeCollected, tokenBridge[_tokenTicker].totalActiveLiquidity);
    // }

    // function getEpochLength(string calldata _tokenTicker) public view returns (uint256) {
    //     return tokenBridge[_tokenTicker].epochLength;
    // }

    // function getStartBlockAndEpochLength(string calldata _tokenTicker) public view returns (uint256, uint256) {
    //     return (tokenBridge[_tokenTicker].startBlock, tokenBridge[_tokenTicker].epochLength);
    // } 

    // function getTokenAddress(string calldata _tokenTicker) public view returns (address) {
    //     return bridgeTokenMetadata[_tokenTicker].tokenAddress;
    // }

    // function getBridgeType(string calldata _tokenTicker) public view returns (uint8) {
    //     return tokenBridge[_tokenTicker].bridgeType;
    // }

    // function isTokenBridgeActive(string calldata _tokenTicker) public view returns (bool) {
    //     return tokenBridge[_tokenTicker].isActive;
    // }

    // function getFeeTypeAndFeeInBips(string calldata _tokenTicker) public view returns (uint8, uint256) {
    //     return (tokenBridge[_tokenTicker].fee.feeType, tokenBridge[_tokenTicker].fee.feeInBips);
    // }

    function updateNoOfDepositors(
        string calldata _tokenTicker,
        bool _isAddingLiquidity
    ) public {
        require(_msgSender() == bridgeUpgradeable, "ONLY_BRIDGE_ALLOWED");
        if(_isAddingLiquidity) {
            ++tokenBridge[_tokenTicker].noOfDepositors;
        }
        else {
            --tokenBridge[_tokenTicker].noOfDepositors;
        }
    }

    function getAllTokenBridges() public view returns (string[] memory) {
        return tokenBridges;
    }

    function removeBridgeToken(string calldata _tokenTicker) external onlyOwner {
        delete bridgeTokenMetadata[_tokenTicker];
    }

    function removeBridge(string memory _tokenTicker) external onlyOwner {
        require(BridgeUpgradeable(payable(bridgeUpgradeable)).totalLpLiquidity(_tokenTicker) == 0, "LIQ_PRESENT");
        require(FeePoolUpgradeable(payable(feePoolUpgradeable)).totalFees(_tokenTicker) == 0, "FEE_PRESENT");
        delete tokenBridge[_tokenTicker];

        uint256 len = tokenBridges.length;
        for (uint256 index = 0; index < len; index++) {
            // string memory token = tokenBridges[index];
            if(keccak256(abi.encodePacked(tokenBridges[index])) == keccak256(abi.encodePacked(_tokenTicker))) {
                if(index < len-1) {
                    tokenBridges[index] = tokenBridges[len-1];
                }
                tokenBridges.pop();
                break;
            }
        }

        emit BridgeRemoved(_tokenTicker);
    }

    receive() external payable {}
}