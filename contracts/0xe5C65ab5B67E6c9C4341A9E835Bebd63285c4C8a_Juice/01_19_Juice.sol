// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @entity: Pinaverse
/// @author: Wizard

/*                                                                                      
                                        ▒▒▒▒
                                      ▒▒▒▒▒▒▒▒▒▒▒▒
                                      ▒▒▒▒  ▒▒▒▒▒▒▓▓
                                      ▒▒▒▒      ▒▒▒▒
                                  ████▒▒▒▒
                              ████░░▒▒▒▒████
                        ██████░░░░░░▒▒▒▒░░░░██
                  ██████░░░░░░░░░░░░░░░░░░██████
                ██████░░░░██░░░░░░░░██████░░░░██
                ██░░░░████░░░░░░████░░░░░░░░░░██
                ██░░██░░░░██████░░░░░░░░░░░░░░██
                ████░░░░████░░░░░░░░░░░░░░░░░░██
                ████░░██░░██░░░░░░░░░░░░░░░░░░██
                ██░░██░░░░██░░░░▒▒░░░░░░░░░░░░██
                ██░░░░░░░░██░░░░░░░░░░░░░░░░░░██
                ██░░░░░░░░██░░░░░ORANGE░░░░░░░██
                ██░░░░░░░░██░░░░░░JUICE░░░░░░░██
                ██░░░░░░░░██░░░░░░░░░░░░░░░░░░██
                ██░░░░░░░░██░░░░░░░░░░░░░░░░░░██
                ██░░░░░░░░██░░░░░░░░░░░░░░░░░░██
                ██░░░░░░░░██░░░░░░░░░░░░░░░░░░██
                ██░░░░░░░░██░░░░▒▒░░░░▒▒░░░░████
                  ██░░░░░░██░░░░░░░░░░░░████
                    ████░░██░░░░░░░░████
                        ████░░██████
                          ████
*/

import "../token/WizardsERC1155.sol";

error MaxJuiceSupplyReached();
error TooManyForRandomRequest();
error RandomRequestsDisabled();
error BurnNotPermitted();
error PaymentFailed();
error NoMoreSelectable();
error MustSetPinaverse();

contract Juice is WizardsERC1155 {
    struct PaymentToken {
        address token;
        uint256 price;
    }

    bool private _allowMerge = false;
    bool private _allowRandom = true;
    address private _pinaverse;

    uint256[5] private _juiceBurnAmount = [3, 3, 3, 10, 1];
    uint256[4] private _jmi = [3555, 1222, 666, 112];
    PaymentToken[] private _paymentToken;

    constructor(
        string memory baseTokenURI,
        string memory contractURI,
        address royaltyRecipient,
        uint24 royaltyValue,
        PaymentToken[] memory paymentTokens
    )
        WizardsERC1155(
            "Pinaverse Juice",
            "j",
            baseTokenURI,
            contractURI,
            royaltyRecipient,
            royaltyValue,
            _msgSender()
        )
    {
        setMaxSupply(0, 3555);
        setMaxSupply(1, 1622);
        setMaxSupply(2, 866);
        setMaxSupply(3, 212);
        setMaxSupply(4, 5);

        for (uint256 i = 0; i < paymentTokens.length; i++) {
            _paymentToken.push(paymentTokens[i]);
        }
    }

    function getPinaverseAddress() public view returns (address) {
        return _pinaverse;
    }

    function getPaymentToken(uint256 id)
        public
        view
        returns (PaymentToken memory)
    {
        return _paymentToken[id];
    }

    function addPaymentToken(PaymentToken memory paymentToken)
        external
        isAdmin
    {
        _paymentToken.push(paymentToken);
    }

    function updatePaymentToken(uint256 id, uint256 price) external isAdmin {
        _paymentToken[id].price = price;
    }

    function setPinaverse(address pinaverse) external isAdmin {
        _pinaverse = pinaverse;
    }

    function toggleAllowMerge() external isAdmin {
        _allowMerge = !_allowMerge;
    }

    function toggleAllowRandom() external isAdmin {
        _allowRandom = !_allowRandom;
    }

    function amountRequired() public view returns (uint256[5] memory) {
        return _juiceBurnAmount;
    }

    function amountRequired(uint256 tier) public view returns (uint256) {
        return _juiceBurnAmount[tier];
    }

    function allowRandom() public view returns (bool) {
        return _allowRandom;
    }

    function allowMerge() public view returns (bool) {
        return _allowMerge;
    }

    function purchase(uint256 quantity, uint256 paymentToken)
        public
        payable
        whenNotPaused
    {
        _payment(quantity, paymentToken);
        _mint(_msgSender(), 0, quantity, "");
    }

    function randomPurchase(uint256 quantity, uint256 paymentToken)
        public
        payable
        whenNotPaused
    {
        if (!_allowRandom) revert RandomRequestsDisabled();
        _payment(quantity, paymentToken);
        _randomMint(_msgSender(), quantity);
    }

    function _payment(uint256 quantity, uint256 paymentToken) private {
        PaymentToken memory p = _paymentToken[paymentToken];
        if (p.price == uint256(0)) revert PaymentFailed();

        uint256 total = quantity * p.price;

        if (p.token == address(0)) {
            if (msg.value < total) revert PaymentFailed();
            return;
        }

        IERC20 erc20 = IERC20(p.token);
        if (erc20.transferFrom(_msgSender(), address(this), total) != true) {
            revert PaymentFailed();
        }
    }

    function randomMint(address to, uint256 quantity)
        public
        isMinter
        whenNotPaused
    {
        if (!_allowRandom) revert RandomRequestsDisabled();
        _randomMint(to, quantity);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public override(WizardsERC1155) {
        super.burn(account, id, value);
        if (_allowMerge) {
            _merge(account, id, value);
        }
    }

    function _randomMint(address account, uint256 quantity) private {
        if (quantity == 1) {
            _mint(account, _weightedSelection(), quantity, "");
        } else {
            if (quantity > 10) revert TooManyForRandomRequest();
            uint256[] memory selected = _expandedWeightedSelection(quantity);
            for (uint256 i = 0; i < selected.length; i++) {
                if (selected[i] > 0) {
                    _mint(account, i, selected[i], "");
                }
            }
        }
    }

    function _weightedSelection() private view returns (uint256) {
        uint256[] memory cumulativeWeights = _juiceCumulativeWeights();

        unchecked {
            uint256 maxWeight = cumulativeWeights[cumulativeWeights.length - 1];
            if (maxWeight == 0) revert NoMoreSelectable();

            uint256 r = _determanisticRandom(1, maxWeight);
            for (uint256 i = 0; i < _jmi.length; i++) {
                if (cumulativeWeights[i] >= r) {
                    return i;
                }
            }
        }
        revert NoMoreSelectable();
    }

    function _expandedWeightedSelection(uint256 n)
        private
        view
        returns (uint256[] memory expandedValues)
    {
        uint256[] memory cumulativeWeights = _juiceCumulativeWeights();
        expandedValues = new uint256[](4);

        unchecked {
            uint256 maxWeight = cumulativeWeights[cumulativeWeights.length - 1];
            if (maxWeight == 0) revert NoMoreSelectable();

            for (uint256 j = 0; j < n; j++) {
                uint256 r = _determanisticRandom(j, maxWeight);
                for (uint256 i = 0; i < _jmi.length; i++) {
                    if (cumulativeWeights[i] >= r) {
                        expandedValues[i]++;
                        break;
                    }
                }
            }
        }
    }

    function _juiceCumulativeWeights() private view returns (uint256[] memory) {
        uint256[] memory cw = new uint256[](4);

        unchecked {
            for (uint256 i = 0; i < _jmi.length; i++) {
                cw[i] =
                    _jmi[i] +
                    (i == 0 ? uint256(0) : cw[i - 1]) -
                    totalMinted(i);
            }
        }
        return cw;
    }

    function _determanisticRandom(uint256 v, uint256 m)
        private
        view
        returns (uint256)
    {
        // this is for fun and random enough
        uint256 r = uint256(keccak256(abi.encodePacked(block.timestamp, v)));
        return r % m;
    }

    function _merge(
        address account,
        uint256 id,
        uint256 value
    ) internal {
        // if user is burning highest tier, revert
        if (id == _juiceBurnAmount.length - 1) revert BurnNotPermitted();

        uint256 tierId = id;
        uint256 nextTierId = tierId + 1;
        uint256 mintQty;
        uint256 tierBurn = _juiceBurnAmount[tierId];

        unchecked {
            // calculate max quantity to be minted
            mintQty = value / tierBurn;
            if (mintQty == 0) return;

            // verify new amount to be minted is not greater than allowable amount
            if (mintQty + totalMinted(tierId) > maxSupply(nextTierId)) {
                revert MaxJuiceSupplyReached();
            }

            // for each higher level, determine if user could receive the next highest tier
            for (uint256 i = nextTierId; i < _juiceBurnAmount.length; i++) {
                uint256 nextTierBurn = _juiceBurnAmount[i];

                if (mintQty >= nextTierBurn) {
                    uint256 tmpToMint = mintQty / nextTierBurn;
                    uint256 remainder = mintQty - (tmpToMint * nextTierBurn);

                    // verify new amount to be minted is not greater than allowable amount
                    if (mintQty + totalMinted(i) > maxSupply(i)) {
                        revert MaxJuiceSupplyReached();
                    }

                    // Issue and burn the tokens for the tier
                    if (i != _juiceBurnAmount.length - 1) {
                        _issuanceCounter[i] += mintQty - remainder;
                        _burnCounter[i] += mintQty - remainder;
                    }

                    // mint the remaining balance resulting from the left over
                    if (remainder > 0) {
                        _mint(account, i, remainder, "");
                    }

                    mintQty = tmpToMint;
                    tierId++;
                } else {
                    // no other conditions met, but the current tier by 1
                    tierId++;
                    break;
                }
            }
        }
        // finally mint the new juice
        _mint(account, tierId, mintQty, "");
    }

    function withdraw() external isAdmin {
        if (_pinaverse == address(0)) revert MustSetPinaverse();
        payable(_pinaverse).transfer(address(this).balance);
    }

    function withdrawToken(address token) external isAdmin {
        if (_pinaverse == address(0)) revert MustSetPinaverse();
        IERC20 erc20 = IERC20(token);
        erc20.transfer(_pinaverse, erc20.balanceOf(address(this)));
    }

    receive() external payable {}
}

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}