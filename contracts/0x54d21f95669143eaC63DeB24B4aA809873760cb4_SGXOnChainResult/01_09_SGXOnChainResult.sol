pragma solidity >=0.4.21 <0.6.0;
import "../SGXRequest.sol";
import "../../../erc20/IERC20.sol";
import "../../../erc20/SafeERC20.sol";
import "../SignatureVerifier.sol";
import "../../../utils/SafeMath.sol";

library SGXOnChainResult{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;
  using SignatureVerifier for bytes32;

  struct ResultParam{
    bytes32 data_hash;
    address payable data_recver;
    ProgramProxyInterface program_proxy;
    uint cost;
    bytes result;
    bytes sig;
    address payable fee_pool;
    uint256 fee;
    uint256 ratio_base;
  }

  function submit_onchain_result(mapping(bytes32=>SGXRequest.Request) storage request_infos,
                        bytes32 request_hash,
                        SGXOnChainResult.ResultParam memory result_param) internal returns(bool){
    require(request_infos[request_hash].exists, "request not exist");
    require(request_infos[request_hash].status == SGXRequest.RequestStatus.init, "invalid status");

    SGXRequest.Request storage r = request_infos[request_hash];

    if(r.target_token != address(0x0)){
      uint amount = result_param.cost.safeMul(r.gas_price);
      uint256 program_price = r.program_use_price;
      amount = amount.safeAdd(r.data_use_price).safeAdd(program_price);

      uint256 fee = 0;
      if(address(result_param.fee_pool) != address(0x0)){
        fee = amount.safeMul(result_param.fee).safeDiv(result_param.ratio_base);
        amount = amount.safeAdd(fee);

        //pay fee
        IERC20(r.target_token).safeTransfer(address(result_param.fee_pool), fee);
      }

      require(amount <= r.token_amount, "insufficient amount to pay onchain result");

      r.status = SGXRequest.RequestStatus.settled;

      //pay data provider
      IERC20(r.target_token).safeTransfer(result_param.data_recver, result_param.cost.safeMul(r.gas_price).safeAdd(r.data_use_price));

      //pay program author
      IERC20(r.target_token).safeTransfer(result_param.program_proxy.program_owner(r.program_hash), program_price);

      uint rest = r.token_amount.safeSub(amount);
      if(rest > 0){
        IERC20(r.target_token).safeTransfer(r.from, rest);
      }
    }

    {
      bytes memory d = abi.encodePacked(r.input, result_param.data_hash, result_param.program_proxy.enclave_hash(r.program_hash), uint64(result_param.cost), result_param.result);
      bytes32 vhash = keccak256(d);
      bool v = vhash.toEthSignedMessageHash().verify_signature(result_param.sig, r.pkey4v);
      require(v, "invalid data");
    }
    return true;
  }
}