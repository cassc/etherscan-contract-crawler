pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/OFTWithFee.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CakeOFT is OFTWithFee, Pausable {
    // Outbound cap
    mapping(uint16 => uint256) public chainIdToOutboundCap;
    mapping(uint16 => uint256) public chainIdToSentTokenAmount;
    mapping(uint16 => uint256) public chainIdToLastSentTimestamp;

    // Inbound cap
    mapping(uint16 => uint256) public chainIdToInboundCap;
    mapping(uint16 => uint256) public chainIdToReceivedTokenAmount;
    mapping(uint16 => uint256) public chainIdToLastReceivedTimestamp;

    // If an address is whitelisted, the inbound/outbound cap checks are skipped
    mapping(address => bool) public whitelist;

    error ExceedOutboundCap(uint256 cap, uint256 amount);
    error ExceedInboundCap(uint256 cap, uint256 amount);

    event SetOperator(address newOperator);
    event SetOutboundCap(uint16 indexed chainId, uint256 cap);
    event SetInboundCap(uint16 indexed chainId, uint256 cap);
    event SetWhitelist(address indexed addr, bool isWhitelist);
    event FallbackWithdraw(address indexed to, uint256 amount);
    event DropFailedMessage(uint16 srcChainId, bytes srcAddress, uint64 nonce);

    constructor(address _lzEndpoint) OFTWithFee("PancakeSwap Token", "Cake", 8, _lzEndpoint){}

    function decimals() public pure override returns (uint8){
        return 18;
    }

    function _debitFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount
    ) internal override whenNotPaused returns (uint256) {
        uint256 amount = super._debitFrom(
            _from,
            _dstChainId,
            _toAddress,
            _amount
        );

        if (whitelist[_from]) {
            return amount;
        }

        uint256 sentTokenAmount;
        uint256 lastSentTimestamp = chainIdToLastSentTimestamp[_dstChainId];
        uint256 currTimestamp = block.timestamp;
        if ((currTimestamp / (1 days)) > (lastSentTimestamp / (1 days))) {
            sentTokenAmount = amount;
        } else {
            sentTokenAmount = chainIdToSentTokenAmount[_dstChainId] + amount;
        }

        uint256 outboundCap = chainIdToOutboundCap[_dstChainId];
        if (sentTokenAmount > outboundCap) {
            revert ExceedOutboundCap(outboundCap, sentTokenAmount);
        }

        chainIdToSentTokenAmount[_dstChainId] = sentTokenAmount;
        chainIdToLastSentTimestamp[_dstChainId] = currTimestamp;

        return amount;
    }

    function _creditTo(
        uint16 _srcChainId,
        address _toAddress,
        uint256 _amount
    ) internal override whenNotPaused returns (uint256) {
        uint256 amount = super._creditTo(_srcChainId, _toAddress, _amount);

        if (whitelist[_toAddress]) {
            return amount;
        }

        uint256 receivedTokenAmount;
        uint256 lastReceivedTimestamp = chainIdToLastReceivedTimestamp[
        _srcChainId
        ];
        uint256 currTimestamp = block.timestamp;
        if ((currTimestamp / (1 days)) > (lastReceivedTimestamp / (1 days))) {
            receivedTokenAmount = amount;
        } else {
            receivedTokenAmount =
            chainIdToReceivedTokenAmount[_srcChainId] +
            amount;
        }

        uint256 inboundCap = chainIdToInboundCap[_srcChainId];
        if (receivedTokenAmount > inboundCap) {
            revert ExceedInboundCap(inboundCap, receivedTokenAmount);
        }

        chainIdToReceivedTokenAmount[_srcChainId] = receivedTokenAmount;
        chainIdToLastReceivedTimestamp[_srcChainId] = currTimestamp;

        return amount;
    }

    function setOutboundCap(uint16 chainId, uint256 cap) external onlyOwner {
        chainIdToOutboundCap[chainId] = cap;
        emit SetOutboundCap(chainId, cap);
    }

    function setInboundCap(uint16 chainId, uint256 cap) external onlyOwner {
        chainIdToInboundCap[chainId] = cap;
        emit SetInboundCap(chainId, cap);
    }

    function setWhitelist(address addr, bool isWhitelist) external onlyOwner {
        whitelist[addr] = isWhitelist;
        emit SetWhitelist(addr, isWhitelist);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}