pragma solidity 0.8.17;

interface IBridge {
    // CBridge
    function send(address _receiver, address _token, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSilippage) external;

    function sendNative(address _receiver, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSlippage) external payable;

    function withdraw(bytes calldata _wdmsg, bytes[] memory _sigs, address[] memory _signers, uint256[] memory _powers) external;

    //polyBridge

    function lock(address fromAsset, uint64 toChainId, bytes memory toAddress, uint256 amount, uint256 fee, uint256 id) external payable;

    //PortalBridge
    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) external payable;

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable;

    function transferTokens(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function wrapAndTransferETH(
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function completeTransferWithPayload(bytes memory encodeVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodeVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodeVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodeVm) external;

    //MultichainBridge
    function anySwapOutUnderlying(address token, address to, uint256 amount, uint256 toChainID) external;

    function anySwapOut(address token, address to, uint256 amount, uint256 toChainID) external;

    function anySwapOutNative(address token, address to, uint256 toChainID) external payable;

    function wNATIVE() external returns (address);

    function transfers(bytes32 transferId) external view returns (bool);
}