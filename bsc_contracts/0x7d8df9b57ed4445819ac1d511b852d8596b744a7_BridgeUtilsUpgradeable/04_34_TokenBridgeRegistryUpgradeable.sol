// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./TokenUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./RegistryStorage.sol";

contract TokenBridgeRegistryUpgradeable is Initializable, OwnableUpgradeable, RegistryStorage {

    // struct BridgeTokenMetadata {
    //     string name;
    //     string imageUrl;
    //     address tokenAddress;
    // }
    
    // // ticker => BridgeTokenMetadata
    // mapping(string => BridgeTokenMetadata) public bridgeTokenMetadata;


    // struct FeeConfig {
    //     uint8 feeType; //0: parent chain; 1: % of tokens
    //     uint256 feeInBips;
    // }

    // struct TokenBridge {
    //     uint8 bridgeType;
    //     string tokenTicker;
    //     uint256 startBlock;
    //     uint256 epochLength;
    //     FeeConfig fee;
    //     // uint256 totalFeeCollected;
    //     // uint256 totalActiveLiquidity;
    //     uint256 noOfDepositors;
    //     bool isActive;
    // }
    // // tokenTicker => TokenBridge
    // mapping(string => TokenBridge) public tokenBridge;

    // // array of all the token tickers
    // string[] public tokenBridges;

    // bool public isBridgeActive;

    address public bridgeUpgradeable;


    event BridgeEnabled();
    event BridgeDisabled();

    event BridgeAdded(
        string tokenTicker,
        string tokenName,
        string imageUrl
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    function updateBridgeAddress(address _newBridgeAddress) external onlyOwner {
        bridgeUpgradeable = _newBridgeAddress;
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
        require(bridgeTokenMetadata[_tokenTicker].tokenAddress != address(0), "TOKEN_NOT_EXISTS");
        require(tokenBridge[_tokenTicker].startBlock == 0, "TOKEN_BRIDGE_ALREADY_EXISTS");
        require(_feeType == 0 || _feeType == 1, "INVALID_FEE_TYPE");

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
        BridgeTokenMetadata memory token = bridgeTokenMetadata[_tokenTicker];
        TokenUpgradeable primaryToken = TokenUpgradeable(bridgeTokenMetadata[_tokenTicker].tokenAddress);
        _deploySetuToken(token.name, _tokenTicker, primaryToken.decimals());

        BridgeUpgradeable(payable(bridgeUpgradeable)).initNextEpochBlock(_tokenTicker, _epochLength);
        
        emit BridgeAdded(_tokenTicker, bridgeTokenMetadata[_tokenTicker].name, bridgeTokenMetadata[_tokenTicker].imageUrl);
    }

    function _deploySetuToken(
        string memory _name, 
        string memory _ticker,
        uint8 _decimals
    ) public onlyOwner {
        TokenUpgradeable setuToken = new TokenUpgradeable();
        // setuToken.initialize(concatenate("setu", _name), concatenate("setu", _ticker), _decimals, _msgSender());

        // deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        bytes memory data = abi.encodeWithSignature("initialize(string,string,uint8,address)", 
                                concatenate("setu", _name), concatenate("setu", _ticker), _decimals, _msgSender());
        // deploy TransparentUpgradeableProxy contract
        TransparentUpgradeableProxy transparentUpgradeableProxy = new TransparentUpgradeableProxy(address(setuToken), address(proxyAdmin), data);

        // transfer ownership of setu token to bridge
        setuToken = TokenUpgradeable(address(transparentUpgradeableProxy));
        setuToken.transferOwnership(bridgeUpgradeable);

        // Add to TokenBridge mapping
        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: concatenate("setu", _name),
            imageUrl: "",
            tokenAddress: address(transparentUpgradeableProxy)
        });
        bridgeTokenMetadata[concatenate("setu", _ticker)] = newBridgeTokenMetadata;
    }

    function concatenate(
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
        if(_feeType == 1) {
            _feeInBips *= 100;
        }
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

    // function getNoOfDepositors(string calldata _tokenTicker) public view returns (uint256) {
    //     return tokenBridge[_tokenTicker].noOfDepositors;
    // }

    function getAllTokenBridges() public view returns (string[] memory) {
        return tokenBridges;
    }

    function removeBridgeToken(string calldata _tokenTicker) external onlyOwner {
        delete bridgeTokenMetadata[_tokenTicker];
    }

    function removeBridge(string memory _tokenTicker) external onlyOwner {
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
    }

    receive() external payable {}
}