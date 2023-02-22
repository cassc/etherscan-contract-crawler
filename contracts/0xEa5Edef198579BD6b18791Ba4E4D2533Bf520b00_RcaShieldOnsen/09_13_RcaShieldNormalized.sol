/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./RcaShieldBase.sol";

contract RcaShieldNormalized is RcaShieldBase {
    using SafeERC20 for IERC20Metadata;

    uint256 immutable BUFFER_UTOKEN;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governor,
        address _controller
    ) RcaShieldBase(_name, _symbol, _uToken, _governor, _controller) {
        BUFFER_UTOKEN = 10**_uTokenDecimals;
    }

    function mintTo(
        address _user,
        address _referrer,
        uint256 _uAmount,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external override {
        // Call controller to check capacity limits, add to capacity limits, emit events, check for new "for sale".
        controller.mint(_user, _uAmount, _expiry, _v, _r, _s, _newCumLiqForClaims, _liqForClaimsProof);

        // Only update fees after potential contract update.
        _update();

        uint256 rcaAmount = _rcaValue(_uAmount, amtForSale);

        // handles decimals diff of underlying tokens
        _uAmount = _normalizedUAmount(_uAmount);
        uToken.safeTransferFrom(msg.sender, address(this), _uAmount);

        _mint(_user, rcaAmount);

        _afterMint(_uAmount);

        emit Mint(msg.sender, _user, _referrer, _uAmount, rcaAmount, block.timestamp);
    }

    function redeemFinalize(
        address _to,
        bytes calldata _routerData,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external override {
        // Removed address user = msg.sender because of stack too deep.

        WithdrawRequest memory request = withdrawRequests[msg.sender];
        delete withdrawRequests[msg.sender];

        // endTime > 0 ensures request exists.
        require(request.endTime > 0 && uint32(block.timestamp) > request.endTime, "Withdrawal not yet allowed.");

        bool isRouterVerified = controller.redeemFinalize(
            msg.sender,
            _to,
            _newCumLiqForClaims,
            _liqForClaimsProof,
            _newPercentReserved,
            _percentReservedProof
        );

        _update();

        pendingWithdrawal -= uint256(request.rcaAmount);

        // handles decimals diff of underlying tokens
        uint256 uAmount = _uValue(request.rcaAmount, amtForSale, percentReserved);
        if (uAmount > request.uAmount) uAmount = request.uAmount;

        uint256 transferAmount = _normalizedUAmount(uAmount);
        uToken.safeTransfer(_to, transferAmount);

        // The cool part about doing it this way rather than having user send RCAs to router contract,
        // then it exchanging and returning Ether is that it's more gas efficient and no approvals are needed.
        if (isRouterVerified) IRouter(_to).routeTo(msg.sender, transferAmount, _routerData);

        emit RedeemFinalize(msg.sender, _to, transferAmount, uint256(request.rcaAmount), block.timestamp);
    }

    function purchaseU(
        address _user,
        uint256 _uAmount,
        uint256 _uEthPrice,
        bytes32[] calldata _priceProof,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external payable override {
        // If user submits incorrect price, tx will fail here.
        controller.purchase(_user, address(uToken), _uEthPrice, _priceProof, _newCumLiqForClaims, _liqForClaimsProof);

        _update();

        uint256 price = _uEthPrice - ((_uEthPrice * discount) / DENOMINATOR);
        // divide by 1 ether because price also has 18 decimals.
        uint256 ethAmount = (price * _uAmount) / 1 ether;
        require(msg.value == ethAmount, "Incorrect Ether sent.");

        // If amount is bigger than for sale, tx will fail here.
        amtForSale -= _uAmount;

        // handles decimals diff of underlying tokens
        _uAmount = _normalizedUAmount(_uAmount);
        uToken.safeTransfer(_user, _uAmount);
        treasury.transfer(msg.value);

        emit PurchaseU(_user, _uAmount, ethAmount, _uEthPrice, block.timestamp);
    }

    function _rcaValue(uint256 _uAmount, uint256 _totalForSale) internal view override returns (uint256 rcaAmount) {
        uint256 balance = _uBalance();

        // Interesting edgecase in which 1 person is in vault, they request redeem,
        // underlying continue to gain value, then withdraw their original value.
        // Vault is then un-useable because below we're dividing 0 by > 0.
        if (balance == 0 || totalSupply() == 0 || balance < _totalForSale) {
            rcaAmount = _uAmount;
        } else {
            rcaAmount = ((totalSupply() + pendingWithdrawal) * _uAmount) / (balance - _totalForSale);
        }

        // normalize for different decimals of uToken and Rca Token
        uint256 normalizingBuffer = BUFFER / BUFFER_UTOKEN;
        if (normalizingBuffer != 0) {
            rcaAmount = (rcaAmount / normalizingBuffer) * normalizingBuffer;
        }
    }

    /**
     * @notice Normalizes underlying token amount by taking consideration of its
     * decimals.
     * @param _uAmount Utoken amount in 18 decimals
     */
    function _normalizedUAmount(uint256 _uAmount) internal view returns (uint256 amount) {
        amount = (_uAmount * BUFFER_UTOKEN) / BUFFER;
    }

    function _uBalance() internal view virtual override returns (uint256) {
        return (uToken.balanceOf(address(this)) * BUFFER) / BUFFER_UTOKEN;
    }

    function _afterMint(uint256) internal virtual override {
        // no-op
    }

    function _afterRedeem(uint256) internal virtual override {
        // no-op
    }
}