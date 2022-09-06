pragma solidity >=0.4.21 <0.6.0;
import "../../../utils/Ownable.sol";
import "../interface/DataMarketPlaceInterface.sol";
import "../../../plugins/GasRewardTool.sol";
import "../../../erc20/IERC20.sol";
import "../../../erc20/SafeERC20.sol";
import "../SGXProxyBase.sol";


interface IMarketCommon{
  function createStaticData(bytes32 _hash,
                            string calldata _extra_info,
                            uint _price,
                            bytes calldata _pkey,
                            bytes calldata _hash_sig) external returns(bytes32);
  function removeStaticData(bytes32 _vhash) external ;
  function transferRequestOwnership(bytes32 _vhash, bytes32 request_hash, address payable new_owner) external;
  function rejectRequest(bytes32 _vhash, bytes32 request_hash) external;
  function changeRequestRevokeBlockNum(bytes32 _vhash, uint256 _new_block_num) external;
  function getRequestOwner(bytes32 _vhash, bytes32 request_hash) external returns(address);
}

contract SGXDataMarketCommon is Ownable, GasRewardTool, SGXProxyBase{

  event SDMarketNewStaticData(bytes32 indexed vhash, bytes32 indexed data_hash, string data_uri, uint price, bytes pkey, bytes hash_sig);
  function createStaticData(bytes32 _hash,
                            string memory _data_uri,
                            uint _price,
                            bytes memory _pkey,
                            bytes memory _hash_sig) public rewardGas returns(bytes32){

    bytes32 vhash;
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.createStaticData.selector, _hash, _data_uri, _price, _pkey, _hash_sig);
      bytes memory ret = market.delegateCallUseData(data_lib_address, data);
      (vhash) = abi.decode(ret, (bytes32));
    }
    market.owner_proxy().initOwnerOf(vhash, msg.sender);

    emit SDMarketNewStaticData(vhash, _hash, _data_uri, _price, _pkey, _hash_sig);
    return vhash;
  }

  event SDMarketRemoveData(bytes32 indexed vhash);
  function removeStaticData(bytes32 _vhash) public rewardGas{
    address owner = getDataOwner(_vhash);
    require(owner == msg.sender, "only owner may remove it");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    bytes memory data = abi.encodeWithSelector(dl.removeStaticData.selector, _vhash);
    emit SDMarketRemoveData(_vhash);
  }

  event SDMarketTransferRequestOwner(address old_owner, address new_owner);
  function transferRequestOwnership(bytes32 _vhash, bytes32 request_hash, address payable new_owner) public{
    address request_owner = getRequestOwner(_vhash, request_hash);
    require(request_owner == msg.sender, "only request owner can transfer");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    bytes memory data = abi.encodeWithSelector(dl.transferRequestOwnership.selector, _vhash, request_hash, new_owner);
    market.delegateCallUseData(data_lib_address, data);
    emit SDMarketTransferRequestOwner(msg.sender, new_owner);
  }

  function getDataOwner(bytes32 _vhash) public view returns(address){
    return market.owner_proxy().ownerOf(_vhash);
  }

  function getRequestOwner(bytes32 _vhash, bytes32 request_hash) public returns(address){
    address owner;
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.getRequestOwner.selector, _vhash, request_hash);
      bytes memory ret = market.delegateCallUseData(data_lib_address, data);
      (owner) = abi.decode(ret, (address));
    }
    return owner;
  }

  event SDMarketRejectRequest(bytes32 indexed vhash, bytes32 indexed request_hash);
  function rejectRequest(bytes32 _vhash, bytes32 request_hash) public rewardGas need_confirm(_vhash, request_hash){
    address data_owner = getDataOwner(_vhash);
    require(data_owner == msg.sender, "only data owner may reject");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.rejectRequest.selector, _vhash, request_hash);
      market.delegateCallUseData(data_lib_address, data);
    }
    emit SDMarketRejectRequest(_vhash, request_hash);
  }

  event SDMarketChangeRequestRevokeBlockNum(bytes32 indexed vhash, uint256 block_num);
  function changeRequestRevokeBlockNum(bytes32 _vhash, uint256 _new_block_num) public rewardGas{
    address data_owner = getDataOwner(_vhash);
    require(data_owner == msg.sender, "only data owner may change request block number");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.changeRequestRevokeBlockNum.selector, _vhash, _new_block_num);
      market.delegateCallUseData(data_lib_address, data);
    }
    emit SDMarketChangeRequestRevokeBlockNum(_vhash, _new_block_num);
  }

  event SDMarketChangeDataPrice(bytes32 indexed vhash, uint256 old_price, uint256 new_price);
  function changeDataPrice(bytes32 _hash, uint256 new_price) public{

    address owner = getDataOwner(_hash);
    require(owner == msg.sender, "only data owner may change price");

    bytes memory d = abi.encodeWithSignature("changeDataPrice(bytes32,uint256)", _hash, new_price);
    bytes memory ret = market.delegateCallUseData(data_lib_address, d);
    (uint256 old_price) = abi.decode(ret, (uint256));
    emit SDMarketChangeDataPrice(_hash, old_price, new_price);
  }

}