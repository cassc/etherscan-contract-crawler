pragma solidity >=0.4.21 <0.6.0;
import "../../utils/Ownable.sol";
import "../../utils/ECDSA.sol";
import "./interface/KeyVerifierInterface.sol";
import "./interface/ProgramProxyInterface.sol";
import "./SGXRequest.sol";



library SGXStaticData {
  using SGXRequest for mapping(bytes32 => SGXRequest.Request);

  struct Data{
    bytes32 data_hash;
    string extra_info; //os, sgx sdk, cpu, compiler, data format, we leave this to user
    uint256 price;
    bytes pkey;
    mapping(bytes32 => SGXRequest.Request) requests;
    bool removed;
    uint256 revoke_timeout_block_num;
    bool exists;
  }


  function init(mapping(bytes32=>SGXStaticData.Data) storage all_data,
                bytes32 _hash,
              string memory _data_uri,
              uint _price, uint256 _revoke_block_num,
              bytes memory _pkey) public returns(bytes32){
    bytes32 vhash = keccak256(abi.encodePacked(_hash, _data_uri, _price, block.number));
    require(!all_data[vhash].exists, "data already exist");
    all_data[vhash].data_hash = _hash;
    all_data[vhash].extra_info= _data_uri;
    all_data[vhash].price = _price;
    all_data[vhash].pkey = _pkey;
    all_data[vhash].removed = false;
    all_data[vhash].revoke_timeout_block_num = _revoke_block_num;
    all_data[vhash].exists = true;

    return vhash;
  }

  function remove(mapping(bytes32=>SGXStaticData.Data) storage all_data,
                  bytes32 _vhash) public {
    require(all_data[_vhash].exists, "data vhash not exist");
    /*require(all_data[_vhash].owner == msg.sender, "only owner can remove the data");*/
    all_data[_vhash].removed = true;
  }

}