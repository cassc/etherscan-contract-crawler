// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

import { ERC721ManagerAutoProxy } from '../ERC721ManagerAutoProxy.sol';
import { NonReentrant } from '../../NonReentrant.sol';
import { Pausable } from '../../Pausable.sol';

import { ICollectionProxy_ManagerFunctions } from '../../interfaces/ICollectionProxy_ManagerFunctions.sol';
import { IERC721ManagerHelperProxy } from '../../interfaces/IERC721ManagerHelperProxy.sol';
import { IERC721ManagerStorage } from '../IERC721ManagerStorage.sol';
import { ICollectionStorage } from '../../interfaces/ICollectionStorage.sol';
import { IERC721Receiver } from '../../interfaces/IERC721Receiver.sol';
import { IGovernedProxy } from '../../interfaces/IGovernedProxy.sol';
import { IStorageBase } from '../../interfaces/IStorageBase.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';

import { Address } from '../../libraries/Address.sol';

pragma solidity 0.8.0;

contract ERC721ManagerHelper is Pausable, NonReentrant, ERC721ManagerAutoProxy {
    using Address for address;

    IERC721ManagerStorage public eRC721ManagerStorage;
    address public weth;

    constructor(address _proxy, address _weth) ERC721ManagerAutoProxy(_proxy, address(this)) {
        // Re-using ERC721ManagerAutoProxy contract for proxy deployment
        weth = _weth;
    }

    modifier requireCollectionProxy() {
        require(
            address(eRC721ManagerStorage.getCollectionStorage(msg.sender)) != address(0),
            'ERC721ManagerHelper: FORBIDDEN, not a Collection proxy'
        );
        _;
    }

    /**
     * @dev Governance functions
     */
    // This function is called in order to upgrade to a new ERC721ManagerHelper implementation
    function destroy(address _newImpl) external requireProxy {
        IStorageBase(address(eRC721ManagerStorage)).setOwnerHelper(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    /**
     * @dev safeMint function
     */
    function safeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool payWithWETH // If set to true, minting fee will be paid in WETH in case msg.value == 0, otherwise minting fee will be paid in mintFeeERC20Asset
    ) external payable noReentry requireCollectionProxy whenNotPaused {
        require(quantity > 0, 'ERC721ManagerHelper: mint at least one NFT');
        // Contract owner can mint for free regardless of whitelist and public mint phases being open or closed.
        // Whitelist mint and public mint phases can be open at the same time.
        // First try to evaluate if the user met the conditions for a whitelist mint then check if the user met the conditions for a public mint.
        if (minter == owner) {
            require(msg.value == 0, 'ERC721ManagerHelper: msg.value should be 0 for owner mint');
            processSafeMint(collectionProxy, minter, to, quantity, false, false);
            // Update ownerMintCount for minter
            eRC721ManagerStorage.setOwnerMintCount(
                collectionProxy,
                eRC721ManagerStorage.getOwnerMintCount(collectionProxy) + quantity
            );
        } else if (
            block.number > eRC721ManagerStorage.getBlockStartWhitelistPhase(collectionProxy) &&
            block.number < eRC721ManagerStorage.getBlockEndWhitelistPhase(collectionProxy) &&
            eRC721ManagerStorage.isWhitelisted(collectionProxy, minter) &&
            quantity <=
            (eRC721ManagerStorage.getMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy) -
                eRC721ManagerStorage.getWhitelistMintCount(collectionProxy, minter))
        ) {
            // Whitelist phase (whitelisted users can mint for free)
            require(
                msg.value == 0,
                'ERC721ManagerHelper: msg.value should be 0 for whitelist mint'
            );
            processSafeMint(collectionProxy, minter, to, quantity, false, false);
            // Update whitelistMintCount for minter
            eRC721ManagerStorage.setWhitelistMintCount(
                collectionProxy,
                minter,
                eRC721ManagerStorage.getWhitelistMintCount(collectionProxy, minter) + quantity
            );
        } else if (
            // If whitelist mint conditions are not met, default to public mint
            block.number > eRC721ManagerStorage.getBlockStartPublicPhase(collectionProxy) &&
            block.number < eRC721ManagerStorage.getBlockEndPublicPhase(collectionProxy)
        ) {
            // Public-sale phase (anyone can mint)
            require(
                quantity <=
                    eRC721ManagerStorage.getMAX_PUBLIC_MINT_PER_ADDRESS(collectionProxy) -
                        eRC721ManagerStorage.getPublicMintCount(collectionProxy, minter),
                'ERC721ManagerHelper: quantity exceeds address allowance'
            );
            processSafeMint(collectionProxy, minter, to, quantity, true, payWithWETH);
            // Update publicMintCount for minter
            eRC721ManagerStorage.setPublicMintCount(
                collectionProxy,
                minter,
                eRC721ManagerStorage.getPublicMintCount(collectionProxy, minter) + quantity
            );
        } else if (
            // If only whitelist mint is open, but the user did not meet the conditions, return an error message
            block.number > eRC721ManagerStorage.getBlockStartWhitelistPhase(collectionProxy) &&
            block.number < eRC721ManagerStorage.getBlockEndWhitelistPhase(collectionProxy)
        ) {
            require(
                eRC721ManagerStorage.isWhitelisted(collectionProxy, minter),
                'ERC721ManagerHelper: address not whitelisted'
            );
            require(
                quantity <=
                    (eRC721ManagerStorage.getMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy) -
                        eRC721ManagerStorage.getWhitelistMintCount(collectionProxy, minter)),
                'ERC721ManagerHelper: quantity exceeds address allowance'
            );
        } else {
            // If minting is not open, return an error message
            revert('ERC721ManagerHelper: minting is not open');
        }
    }

    /**
     * @dev Private functions (safeMint logic)
     */
    function processSafeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool publicPhase,
        bool payWithWETH
    ) private {
        ICollectionStorage collectionStorage = eRC721ManagerStorage.getCollectionStorage(
            collectionProxy
        );
        // Make sure mint won't exceed max supply
        uint256 _totalSupply = collectionStorage.getTotalSupply();
        require(
            _totalSupply + quantity <= eRC721ManagerStorage.getMAX_SUPPLY(collectionProxy),
            'ERC721ManagerHelper: purchase would exceed max supply'
        );
        if (publicPhase) {
            // Process mint fee payment for public mints
            processMintFee(collectionProxy, minter, quantity, payWithWETH);
        } else {
            // Emit MintFee event
            IERC721ManagerHelperProxy(proxy).emitMintFee(
                collectionProxy,
                minter,
                quantity,
                address(0), // mintFeeRecipient is set to address(0) for owner mints and whitelist phase MintFee events
                address(0), // mintFeeAsset is set to address(0) for owner mints and whitelist phase MintFee events
                0 // mintFee is set to 0 for owner mints and whitelist phase MintFee events
            );
        }
        // Mint
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(collectionProxy, collectionStorage, minter, to, '');
        }
    }

    function processMintFee(
        address collectionProxy,
        address minter,
        uint256 quantity,
        bool payWithWETH
    ) private {
        if (msg.value > 0 || payWithWETH) {
            // If msg.value > 0 or payWithWETH == true, we attempt to process ETH/WETH mint fee payment
            // Calculate total ETH/WETH mint fee to mint quantity
            (
                uint256 totalMintFeeETH,
                uint256 lastETHMintFeeAboveThreshold,
                uint256 ethMintsCount
            ) = getTotalMintFeeETH(collectionProxy, quantity);
            // Record lastETHMintFeeAboveThreshold into collection storage
            if (lastETHMintFeeAboveThreshold > 0) {
                eRC721ManagerStorage.setLastETHMintFeeAboveThreshold(
                    collectionProxy,
                    lastETHMintFeeAboveThreshold
                );
            }
            // Check that MAX_ETH_MINTS will not be exceeded
            require(
                ethMintsCount + quantity <= eRC721ManagerStorage.getMAX_ETH_MINTS(collectionProxy),
                'ERC721ManagerHelper: purchase would exceed max ETH mints'
            );
            // Update collection's eth mints count
            eRC721ManagerStorage.setETHMintsCount(collectionProxy, ethMintsCount + quantity);
            // Get mintFeeRecipient
            address mintFeeRecipient = eRC721ManagerStorage.getMintFeeRecipient();
            if (msg.value > 0) {
                // Attempt to process ETH mint fee payment
                // Transfer mint fee
                if (msg.value >= totalMintFeeETH) {
                    // Transfer totalMintFeeETH to mintFeeRecipient
                    (bool _success, bytes memory _data) = mintFeeRecipient.call{
                        value: totalMintFeeETH
                    }('');
                    require(
                        _success && (_data.length == 0 || abi.decode(_data, (bool))),
                        'ERC721ManagerHelper: failed to transfer ETH mint fee'
                    );
                    // Emit MintFee event
                    IERC721ManagerHelperProxy(proxy).emitMintFee(
                        collectionProxy,
                        minter,
                        quantity,
                        mintFeeRecipient,
                        address(0), // mintFeeAsset is set to address(0) when mint fee is paid with ETH
                        totalMintFeeETH
                    );
                } else {
                    revert('ERC721ManagerHelper: msg.value is too small to pay mint fee');
                }
                // Resend excess funds to user
                uint256 balance = address(this).balance;
                (bool success, bytes memory data) = minter.call{ value: balance }('');
                require(
                    success && (data.length == 0 || abi.decode(data, (bool))),
                    'ERC721ManagerHelper: failed to transfer excess ETH back to minter'
                );
            } else {
                // Attempt to process ERC20 mint fee payment using WETH
                IERC721ManagerHelperProxy(proxy).safeTransferERC20From(
                    weth,
                    minter,
                    mintFeeRecipient,
                    totalMintFeeETH
                );
                // Emit MintFee event
                IERC721ManagerHelperProxy(proxy).emitMintFee(
                    collectionProxy,
                    minter,
                    quantity,
                    mintFeeRecipient,
                    weth,
                    totalMintFeeETH
                );
            }
        } else {
            // Attempt to process ERC20 mint fee payment using mintFeeERC20Asset
            address mintFeeERC20AssetProxy = eRC721ManagerStorage.getMintFeeERC20AssetProxy(
                collectionProxy
            );
            uint256 mintFeeERC20 = eRC721ManagerStorage.getMintFeeERC20(collectionProxy) * quantity;
            // Burn mintFeeERC20Asset from minter
            IERC20(IGovernedProxy(payable(address(uint160(mintFeeERC20AssetProxy)))).impl()).burn(
                minter,
                mintFeeERC20
            );
            // Emit MintFee event
            IERC721ManagerHelperProxy(proxy).emitMintFee(
                collectionProxy,
                minter,
                quantity,
                address(0), // mintFeeRecipient is set to address(0) when mint fee is paid by burning mintFeeERC20 token
                mintFeeERC20AssetProxy,
                mintFeeERC20
            );
        }
    }

    function getTotalMintFeeETH(
        address collectionProxy,
        uint256 quantity
    )
        public
        view
        returns (
            uint256 totalMintFeeETH,
            uint256 lastETHMintFeeAboveThreshold,
            uint256 ethMintsCount
        )
    {
        ethMintsCount = eRC721ManagerStorage.getETHMintsCount(collectionProxy);
        uint256 ethMintsCountThreshold = eRC721ManagerStorage.getETHMintsCountThreshold(
            collectionProxy
        );
        if (ethMintsCount >= ethMintsCountThreshold) {
            (totalMintFeeETH, lastETHMintFeeAboveThreshold) = calculateOverThresholdMintFeeETH(
                collectionProxy,
                quantity
            );
        } else if (ethMintsCount + quantity <= ethMintsCountThreshold) {
            uint256 baseMintFeeETH = eRC721ManagerStorage.getBaseMintFeeETH(collectionProxy);
            totalMintFeeETH = baseMintFeeETH * quantity;
            lastETHMintFeeAboveThreshold = 0;
        } else {
            // Calculate ETH mint fee for mints below ethMintsCountThreshold
            uint256 subThresholdQuantity = ethMintsCountThreshold - ethMintsCount;
            uint256 baseMintFeeETH = eRC721ManagerStorage.getBaseMintFeeETH(collectionProxy);
            uint256 subThresholdMintFeeETH = baseMintFeeETH * subThresholdQuantity;
            // Calculate ETH mint fee for mints above ethMintsCountThreshold
            uint256 overThresholdQuantity = quantity - subThresholdQuantity;
            uint256 overThresholdMintFeeETH;
            (
                overThresholdMintFeeETH,
                lastETHMintFeeAboveThreshold
            ) = calculateOverThresholdMintFeeETH(collectionProxy, overThresholdQuantity);
            // Calculate total ETH mint fee
            totalMintFeeETH = subThresholdMintFeeETH + overThresholdMintFeeETH;
        }
    }

    function calculateOverThresholdMintFeeETH(
        address collectionProxy,
        uint256 quantity
    ) private view returns (uint256 totalMintFeeETH, uint256 lastETHMintFeeAboveThreshold) {
        // After ethMintCountThreshold ETH mints, the ETH mint price will increase by ethMintFeeGrowthRateBps bps
        // for every mint
        uint256 ethMintFeeGrowthRateBps = eRC721ManagerStorage.getETHMintFeeGrowthRateBps(
            collectionProxy
        );
        uint256 feeDenominator = eRC721ManagerStorage.getFeeDenominator();
        totalMintFeeETH = 0;
        lastETHMintFeeAboveThreshold = eRC721ManagerStorage.getLastETHMintFeeAboveThreshold(
            collectionProxy
        );
        for (uint256 i = 1; i <= quantity; i++) {
            uint256 mintFeeETHAtIndex = (lastETHMintFeeAboveThreshold *
                (feeDenominator + ethMintFeeGrowthRateBps)) / feeDenominator;
            totalMintFeeETH = totalMintFeeETH + mintFeeETHAtIndex;
            lastETHMintFeeAboveThreshold = mintFeeETHAtIndex;
        }
    }

    function _safeMint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to,
        bytes memory _data
    ) private {
        uint256 tokenId = _mint(collectionProxy, collectionStorage, to);
        require(
            _checkOnERC721Received(minter, address(0), to, tokenId, _data),
            'ERC721ManagerHelper: transfer to non ERC721Receiver implementer'
        );
    }

    function _mint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address to
    ) internal virtual returns (uint256) {
        require(to != address(0), 'ERC721ManagerHelper: mint to the zero address');
        // Calculate tokenId
        uint256 tokenId = collectionStorage.getTokenIdsCount() + 1;
        // Register tokenId
        collectionStorage.pushTokenId(tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() + 1);
        // Register tokenId ownership
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(address(0), to, tokenId);

        return tokenId;
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721ManagerHelper: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Owner-restricted functions
     */
    function airdrop(
        address collectionProxy,
        address[] calldata recipients,
        uint256[] calldata numbers
    ) external onlyOwner {
        require(
            recipients.length == numbers.length,
            'ERC721ManagerHelper: recipients and numbers arrays must have the same length'
        );
        ICollectionStorage collectionStorage = eRC721ManagerStorage.getCollectionStorage(
            collectionProxy
        );
        for (uint256 j = 0; j < recipients.length; j++) {
            for (uint256 i = 0; i < numbers[j]; i++) {
                _safeMint(collectionProxy, collectionStorage, msg.sender, recipients[j], '');
            }
        }
    }

    function setManagerStorage(address _eRC721ManagerStorage) external onlyOwner {
        eRC721ManagerStorage = IERC721ManagerStorage(_eRC721ManagerStorage);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IERC721ManagerHelperProxy(proxy).setSporkProxy(_sporkProxy);
    }

    function setMintFeeRecipient(address mintFeeRecipient) external onlyOwner {
        eRC721ManagerStorage.setMintFeeRecipient(mintFeeRecipient);
    }

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address mintFeeERC20AssetProxy
    ) external onlyOwner {
        eRC721ManagerStorage.setMintFeeERC20AssetProxy(collectionProxy, mintFeeERC20AssetProxy);
    }

    function setMintFeeERC20(address collectionProxy, uint256 mintFeeERC20) external onlyOwner {
        eRC721ManagerStorage.setMintFeeERC20(collectionProxy, mintFeeERC20);
    }

    function setBaseMintFeeETH(address collectionProxy, uint256 baseMintFeeETH) external onlyOwner {
        eRC721ManagerStorage.setBaseMintFeeETH(collectionProxy, baseMintFeeETH);
        uint256 ethMintsCountThreshold = eRC721ManagerStorage.getETHMintsCountThreshold(
            collectionProxy
        );
        if (eRC721ManagerStorage.getETHMintsCount(collectionProxy) <= ethMintsCountThreshold) {
            // Update lastETHMintFeeAboveThreshold
            eRC721ManagerStorage.setLastETHMintFeeAboveThreshold(collectionProxy, baseMintFeeETH);
        }
    }

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 ethMintFeeGrowthRateBps
    ) external onlyOwner {
        eRC721ManagerStorage.setETHMintFeeGrowthRateBps(collectionProxy, ethMintFeeGrowthRateBps);
    }

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 ethMintsCountThreshold
    ) external onlyOwner {
        eRC721ManagerStorage.setETHMintsCountThreshold(collectionProxy, ethMintsCountThreshold);
    }
}