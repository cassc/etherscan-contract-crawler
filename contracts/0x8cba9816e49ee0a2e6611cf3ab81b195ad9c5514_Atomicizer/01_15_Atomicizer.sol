// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./MarketRegistry.sol";
import "./SpecialTransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

// Contract was inspired by Gemswap contract at 0x83c8f28c26bf6aaca652df1dbbe0e1b56f8baba2, MIT License
contract Atomicizer is
    SpecialTransferHelper,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ConverstionDetails {
        bytes conversionData;
    }

    address public converter;
    address public punkProxy;
    MarketRegistry public marketRegistry;

    function initialize(address _marketRegistry) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        marketRegistry = MarketRegistry(_marketRegistry);
    }

    // Create a UserProxy contract for the WrappedPunk
    function setUpWrappedPunk() external onlyOwner {
        // Create CryptoPunk Proxy
        IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).registerProxy();
        punkProxy = IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6)
            .proxyInfo(address(this));
    }

    // Grant approval for the MoonCatsWrapped in the MoonCatAcclimator
    function setUpMooncats() external onlyOwner {
        // approve wrapped mooncats rescue to Acclimated​MoonCats contract
        IERC721Upgradeable(0x7C40c393DC0f283F318791d746d894DdD3693572)
            .setApprovalForAll(
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69,
                true
            );
    }

    // This function is used to approve specific tokens to specific market contracts with high volume.
    // This is done in very rare cases for the gas optimization purposes.
    function setOneTimeApproval(
        IERC20Upgradeable token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    function setConverter(address _converter) external onlyOwner {
        converter = _converter;
    }

    function setMarketRegistry(MarketRegistry _marketRegistry)
        external
        onlyOwner
    {
        marketRegistry = _marketRegistry;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _transferFromHelper(
        ERC20Details memory erc20Details,
        SpecialTransferHelper.ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details
    ) internal {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(
                abi.encodeWithSelector(
                    0x23b872dd,
                    msg.sender,
                    address(this),
                    erc20Details.amounts[i]
                )
            );
        }

        // transfer ERC721 tokens from the sender to this contract
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunks
            if (
                erc721Details[i].tokenAddr ==
                0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB
            ) {
                _acceptCryptoPunk(erc721Details[i]);
            }
            // accept Mooncat
            else if (
                erc721Details[i].tokenAddr ==
                0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6
            ) {
                _acceptMoonCat(erc721Details[i]);
            }
            // default
            else {
                for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                    IERC721Upgradeable(erc721Details[i].tokenAddr).transferFrom(
                            _msgSender(),
                            address(this),
                            erc721Details[i].ids[j]
                        );
                }
            }
        }

        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155Upgradeable(erc1155Details[i].tokenAddr)
                .safeBatchTransferFrom(
                    _msgSender(),
                    address(this),
                    erc1155Details[i].ids,
                    erc1155Details[i].amounts,
                    ""
                );
        }
    }

    function _conversionHelper(ConverstionDetails[] memory _converstionDetails)
        internal
    {
        for (uint256 i = 0; i < _converstionDetails.length; i++) {
            // convert to desired asset
            (bool success, ) = converter.delegatecall(
                _converstionDetails[i].conversionData
            );
            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _trade(MarketRegistry.TradeDetails[] memory _tradeDetails)
        internal
    {
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            // get market details
            (address _proxy, bool _isLib, bool _isActive) = marketRegistry
                .markets(_tradeDetails[i].marketId);
            // market should be active
            require(_isActive, "_trade: InActive Market");
            // execute trade
            (bool success, ) = _isLib
                ? _proxy.delegatecall(_tradeDetails[i].tradeData)
                : _proxy.call{value: _tradeDetails[i].value}(
                    _tradeDetails[i].tradeData
                );

            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _returnDust(address[] memory _tokens) internal {
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
        // return remaining tokens (if any)
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (IERC20Upgradeable(_tokens[i]).balanceOf(address(this)) > 0) {
                _tokens[i].call(
                    abi.encodeWithSelector(
                        0xa9059cbb,
                        msg.sender,
                        IERC20Upgradeable(_tokens[i]).balanceOf(address(this))
                    )
                );
            }
        }
    }

    function batchBuyWithETH(MarketRegistry.TradeDetails[] memory tradeDetails)
        external
        payable
        nonReentrant
    {
        // execute trades
        _trade(tradeDetails);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function batchBuyWithERC20s(
        ERC20Details memory erc20Details,
        MarketRegistry.TradeDetails[] memory tradeDetails,
        ConverstionDetails[] memory converstionDetails,
        address[] memory dustTokens
    ) external payable nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(
                abi.encodeWithSelector(
                    0x23b872dd,
                    msg.sender,
                    address(this),
                    erc20Details.amounts[i]
                )
            );
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) external onlyOwner {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        asset.call(
            abi.encodeWithSelector(
                0xa9059cbb,
                recipient,
                IERC20Upgradeable(asset).balanceOf(address(this))
            )
        );
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(
        address asset,
        uint256[] calldata ids,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721Upgradeable(asset).transferFrom(
                address(this),
                recipient,
                ids[i]
            );
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(
        address asset,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155Upgradeable(asset).safeTransferFrom(
                address(this),
                recipient,
                ids[i],
                amounts[i],
                ""
            );
        }
    }
}