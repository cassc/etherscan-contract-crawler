// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

import "layerzerolabs/contracts/interfaces/IStargateReceiver.sol";
import "layerzerolabs/contracts/token/oft/IOFTCore.sol";
import "communal/SafeERC20.sol";
import "communal/Owned.sol";
import "communal/TransferHelper.sol";


interface IunshethZap {
    function mint_with_usdt(uint256 amount, uint256 min_amount_unshethZap, uint256 unsheth_path) external;
}

interface IStargateRouter {
    function clearCachedSwap(uint16 _srcChainId, bytes calldata _srcAddress, uint256 nonce) external;
    function cachedSwapLookup(uint16 _srcChainId, bytes calldata _srcAddress, uint256 nonce) external view returns (address token, uint256 amountLD, address to, bytes memory payload);
}


contract USDTSGReceiver is IStargateReceiver, Owned {

    address public immutable stargateRouterAddress;
    address public unshethZapAddress;
    address public immutable usdtAddress;
    address public immutable unshethAddress;
    address public immutable proxyUnshethAddress;
    address public zroAddress = address(0);
    uint256 public unsheth_gas_cost;

    uint16 public srcChainId;

    mapping(uint256 => bool) public nonceHandled;

    //adapter params
    uint256 public adapter_version = 2;
    uint256 public adapter_gasLimit = 200000;
    uint256 public adapter_airdrop = 0;

    using SafeERC20 for IERC20;

    //to see chain ids and stargate router addresses, check out 
    //https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    //https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet

    constructor(
        address _owner,  //address of the person deploying this
        address _proxyUnshethAddress, //address of the proxy unshETH deployed
        address _unshETHAddress, //address of unshETH token contract
        address _usdtAddress, //usdt address - 0xdac17f958d2ee523a2206206994597c13d831ec7
        address _stargateRouter, //0x8731d54E9D02c286767d56ac03e8037C07e01e98 as per https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
        address _unshethZapAddress, //address of the unshETH Zap deployed
        uint16 _srcChainId //102 as per https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    ) Owned(_owner) {
        proxyUnshethAddress = _proxyUnshethAddress;
        stargateRouterAddress = _stargateRouter;
        unshethZapAddress = _unshethZapAddress;
        usdtAddress = _usdtAddress;
        unshethAddress = _unshETHAddress;
        unsheth_gas_cost = 0.01 ether;
        srcChainId = _srcChainId;
        
        //allow the unsheth zap to execute sendFrom for all USDT sent over
        TransferHelper.safeApprove(usdtAddress, unshethZapAddress, type(uint256).max);
        //allow the unsheth proxy to spend my unsheth
        TransferHelper.safeApprove(unshethAddress, proxyUnshethAddress, type(uint256).max);
    }

    //owner function to set the srcChainId and srcAddress
    function updateSrcChainId(uint16 _srcChainId) public onlyOwner{
        srcChainId = _srcChainId;
    }

    function updateAdapterParams(uint256 _version, uint256 _gasLimit, uint256 _airdrop) public onlyOwner {
        adapter_version = _version;
        adapter_gasLimit = _gasLimit;
        adapter_airdrop = _airdrop;
    }

    //owner function to set the zroAddress
    function updateZroAddress(address _zroAddress) public onlyOwner{
        zroAddress = _zroAddress;
    }

    //owner function to set the amount of eth to spend per unsheth transfer
    function set_unsheth_gas_cost(uint256 amount) public onlyOwner{
        unsheth_gas_cost = amount;
    }

    //sgReceive will receive USDT and then mint unshETH and send the unshETH back to the original sender
    function sgReceive(uint16 /*_chainId*/, bytes memory /*_srcAddress*/, uint /*_nonce*/, address _token, uint amountLD, bytes memory _payload) override external {
        require(msg.sender == address(stargateRouterAddress), "only stargate router can call sgReceive!");
        require(_token == usdtAddress, "only USDT can be sent to this contract!");
        require(unsheth_gas_cost <= address(this).balance, 'unsheth_gas_cost must be less than the eth balance in this contract');
        //Check the balance of USDT is above the amountLD
        require(amountLD <= IERC20(usdtAddress).balanceOf(address(this)), "Contract USDT balance is less than amountLD");
        //Extract the mint information
        (address userAddress, uint256 min_amount_unshethZap, uint256 unsheth_path) = abi.decode(_payload, (address, uint256, uint256));
        //Mint unsheth with usdt using the parameters bridged over
        uint256 unshethMinted = _mint_unsheth_with_usdt(amountLD, min_amount_unshethZap, unsheth_path);
        //Bridge the minted unsheth
        _bridge_unsheth(unshethMinted, unsheth_gas_cost, userAddress);
    }

    function _mint_unsheth_with_usdt(uint256 _usdtAmount, uint256 _minAmountOut, uint256 _pathId) internal returns (uint256 unshethMinted) {
        //get balance of unshETH before minting
        uint256 unshethBalBefore = IERC20(unshethAddress).balanceOf(address(this));
        //Mint unshETH to this contract address
        IunshethZap(unshethZapAddress).mint_with_usdt(_usdtAmount, _minAmountOut, _pathId);
        //get the new balance of unshETH
        uint256 unshethBal = IERC20(unshethAddress).balanceOf(address(this));
        //return unshethMinted = the difference in balances
        return (unshethBal - unshethBalBefore);
    }

    function _bridge_unsheth(uint256 _unshethAmount, uint256 _unsheth_gas_cost, address _userAddress) internal {
        IOFTCore(proxyUnshethAddress).sendFrom{value:_unsheth_gas_cost}(
            address(this), //current owner of the unsheth
            srcChainId, //chain Id where the proxy of the unsheth exists (this is set in the constructor)
            abi.encodePacked(_userAddress), //the address we want the unsheth to end up in
            _unshethAmount, //the amount of unsheth to send
            payable(address(this)), //the refund address if something goes wrong or excess
            zroAddress, //the ZRO Payment Address
            //Adapter params
            abi.encode( 
                adapter_version,
                adapter_gasLimit,
                adapter_airdrop,
                _userAddress
            ) 
        );
    }

    //function for user to rescue the usdt bridged over in case initial bridge txn fails
    function rescue_usdt(bytes memory srcAddress, uint256 nonce) external {
        //Ensure this nonce hasn't already been handled
        require(nonceHandled[nonce] == false, "Nonce has already been handled");
        (address _token, uint256 amountLD, address to, bytes memory _payload) = IStargateRouter(stargateRouterAddress).cachedSwapLookup(srcChainId, srcAddress, nonce);
        (address userAddress, , ) = abi.decode(_payload, (address, uint256, uint256));
        //Check parameters are reasonable
        require(to == address(this), "to is not sgreceiver contract address");
        require(_token == usdtAddress, "only USDT can be sent to this contract!");
        require(msg.sender == userAddress || msg.sender == owner, "only owner or user can rescue their usdt");
        require(amountLD > 0, "No tokens to rescue");
        require(amountLD <= IERC20(usdtAddress).balanceOf(address(this)), "Amount to rescue exceeds contract balance");
        TransferHelper.safeTransfer(usdtAddress, userAddress, amountLD);
        nonceHandled[nonce] = true;
    }

    //owner function to clear the cache with same params as before in case initial bridge txn fails. Gas is paid by team
    function retry_mint_clearCachedSwap(bytes memory srcAddress, uint256 nonce) external onlyOwner {
        IStargateRouter(stargateRouterAddress).clearCachedSwap(srcChainId, srcAddress, nonce);
        nonceHandled[nonce] = true;
    }

    //function for user to retry minting unsheth with usdt with new params in case initial bridge txn fails
    //front-end should suggest min_amount_unshethZap and unsheth_path based on optimal path to mint unsheth with usdt
    //front-end should also suggest msg.value which corresponds to gas cost of bridging unsheth to bnb
    function retry_mint_newParams(bytes memory srcAddress, uint256 nonce, uint256 min_amount_unshethZap, uint256 unsheth_path) external payable {
        //Ensure this nonce hasn't already been handled
        require(nonceHandled[nonce] == false, "Nonce has already been handled");
        //Extract the stargate cachedswap information with the given nonce
        (address _token, uint256 amountLD, address to, bytes memory _payload) = IStargateRouter(stargateRouterAddress).cachedSwapLookup(srcChainId, srcAddress, nonce);
        (address userAddress, , ) = abi.decode(_payload, (address, uint256, uint256));
        //Check parameters are reasonable
        require(to == address(this), "to is not sgreceiver contract address");
        require(_token == usdtAddress, "only USDT can be sent to this contract!");
        require(msg.sender == userAddress, "only user can retry mint");
        require(amountLD > 0, "No tokens to retry with");
        require(amountLD <= IERC20(usdtAddress).balanceOf(address(this)), "Amount to retry with exceeds contract balance");
        //Mint unsheth with usdt using the retry parameters
        uint256 unshethMinted = _mint_unsheth_with_usdt(amountLD, min_amount_unshethZap, unsheth_path);
        //Bridge the minted unsheth
        _bridge_unsheth(unshethMinted, msg.value, userAddress);
        nonceHandled[nonce] = true;
    }

    function updateUnshethZapAddress(address _unshethZapAddress) external onlyOwner {
        require(_unshethZapAddress != address(0), "Invalid address");
        //Remove approval of old unshETHZap Addresss
        TransferHelper.safeApprove(usdtAddress, unshethZapAddress, 0);

        //Set new unshETH Zap Address
        unshethZapAddress = _unshethZapAddress;

        //Approve new unshETHZap Address
        TransferHelper.safeApprove(usdtAddress, unshethZapAddress, type(uint256).max);
    }

    //owner function that sends the remaining eth back to the owner
    function rescue_eth() external onlyOwner{
        uint256 ethBal = address(this).balance;
        Address.sendValue(payable(owner), ethBal);
    }

    function emergency_rescue_usdt() external onlyOwner {
        uint256 usdtBal = IERC20(usdtAddress).balanceOf(address(this));
        TransferHelper.safeTransfer(usdtAddress, owner, usdtBal);
    }

    //Allow receiving eth to the contract
    receive() external payable {}
}