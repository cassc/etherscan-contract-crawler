/**************************
  ___  ____  ____  ____   ___   ___  ____    ___    
|_  ||_  _||_  _||_  _|.'   `.|_  ||_  _| .'   `.  
  | |_/ /    \ \  / / /  .-.  \ | |_/ /  /  .-.  \ 
  |  __'.     \ \/ /  | |   | | |  __'.  | |   | | 
 _| |  \ \_   _|  |_  \  `-'  /_| |  \ \_\  `-'  / 
|____||____| |______|  `.___.'|____||____|`.___.'  

 **************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ProjectConfig } from "./ProjectConfig.sol";
import "./interface.sol";

import { ValidateLogic } from "./libs/ValidateLogic.sol";
import { Errors } from "./libs/Errors.sol";

import "./LayerZero/ILayerZeroUserApplicationConfig.sol";
import "./LayerZero/ILayerZeroReceiver.sol";
import "./LayerZero/ILayerZeroEndpoint.sol";

abstract contract BaseContract is
    Initializable,
    ProjectConfig,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721HolderUpgradeable,
    AccessControlEnumerableUpgradeable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    CountersUpgradeable.Counter private _internalId;

    uint16 public selfChainId;

    // internalId => DepositAsset
    mapping(uint => ICCAL.DepositAsset) public nftMap;

    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721HolderUpgradeable) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function initialize(
        address _endpoint,
        uint16 _selfChainId
    ) internal virtual onlyInitializing {
        selfChainId = _selfChainId;
        layerZeroEndpoint = ILayerZeroEndpoint(_endpoint);

        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    event LogDepositAsset(
        address indexed game,
        address indexed depositor,
        uint indexed internalId,
        uint[] toolIds,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle,
        address token,
        uint time
    );
    function deposit(
        address game,
        address token,
        uint[] memory toolIds,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle
    ) external {
        ValidateLogic.checkDepositPara(game, toolIds, amountPerDay, totalAmount, minPay, cycle);
        require(checkTokenInList(token), Errors.VL_TOKEN_NOT_SUPPORT);

        uint internalId = getInternalId();

        uint len = toolIds.length;
        for (uint i = 0; i < len;) {
            IERC721Upgradeable(game).safeTransferFrom(_msgSender(), address(this), toolIds[i]);
            unchecked {
                ++i;
            }
        }

        nftMap[internalId] = ICCAL.DepositAsset({
            depositTime: block.timestamp,
            amountPerDay: amountPerDay,
            status: ICCAL.AssetStatus.INITIAL,
            totalAmount: totalAmount,
            internalId: internalId,
            holder: _msgSender(),
            borrower: address(0),
            toolIds: toolIds,
            minPay: minPay,
            token: token,
            borrowTime: 0,
            game: game,
            cycle: cycle,
            borrowIndex: 0
        });

        address _token = token;

        emit LogDepositAsset(game, _msgSender(), internalId, toolIds, amountPerDay, totalAmount, minPay, cycle, _token, block.timestamp);
    }

    event LogEditDepositAsset(
        uint indexed internalId,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle,
        address token
    );
    function editDepositAsset(
        uint internalId,
        address token,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle
    ) external whenNotPaused {
        ValidateLogic.checkEditPara(
            _msgSender(),
            amountPerDay,
            totalAmount,
            minPay,
            cycle,
            internalId,
            nftMap
        );

        require(checkTokenInList(token), Errors.VL_TOKEN_NOT_SUPPORT);

        nftMap[internalId] = ICCAL.DepositAsset({
            borrowIndex: nftMap[internalId].borrowIndex,
            depositTime: nftMap[internalId].depositTime,
            toolIds: nftMap[internalId].toolIds,
            game: nftMap[internalId].game,
            amountPerDay: amountPerDay,
            status: ICCAL.AssetStatus.INITIAL,
            totalAmount: totalAmount,
            internalId: internalId,
            holder: _msgSender(),
            borrower: address(0),
            minPay: minPay,
            token: token,
            borrowTime: 0,
            cycle: cycle
        });

        emit LogEditDepositAsset(internalId, amountPerDay, totalAmount, minPay, cycle, token);
    }

    function getInternalId() internal returns(uint) {
        _internalId.increment();
        return _internalId.current();
    }

    function lzReceive(
        uint16,
        bytes memory,
        uint64, /*_nonce*/
        bytes memory/*_payload*/
    ) external virtual override {}

    function setRemote(uint16 _chainId, bytes calldata _remoteAdr) external onlyOwner {
        remotes[_chainId] = _remoteAdr;
    }

    function setConfig(
        uint16, /*_version*/
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external override {
        layerZeroEndpoint.setConfig(layerZeroEndpoint.getSendVersion(address(this)), _chainId, _configType, _config);
    }

    function getConfig(
        uint16, /*_dstChainId*/
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
        return layerZeroEndpoint.getConfig(layerZeroEndpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }

    function setSendVersion(uint16 version) external override {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override {
        layerZeroEndpoint.setReceiveVersion(version);
    }

    function getSendVersion() external view returns (uint16) {
        return layerZeroEndpoint.getSendVersion(address(this));
    }

    function getReceiveVersion() external view returns (uint16) {
        return layerZeroEndpoint.getReceiveVersion(address(this));
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        layerZeroEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    event LogToggleTokens(address token, bool active);
    function toggleTokens(
        address token,
        uint8 decimals,
        bool stable,
        bool active
    ) public onlyOwner returns(bool) {
        if (active) {
            tokenInfos[token].active = true;
            tokenInfos[token].decimals = decimals;
            tokenInfos[token].stable = stable;
            return true;
        }
        delete tokenInfos[token];
        emit LogToggleTokens(token, active);
        return true;
    }
    
    function checkTokenInList(address _token) internal view returns(bool) {
        return tokenInfos[_token].active;
    }
    
    event LogWithdrawETH(address user);
    function withdrawETH() external onlyOwner returns(bool) {
        (bool success, ) = _msgSender().call{value: address(this).balance}(new bytes(0));
        emit LogWithdrawETH(_msgSender());
        return success;
    }

    function togglePause(bool needPause) external onlyOwner {
        if (needPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    fallback() external payable {}

    receive() external payable {}
}