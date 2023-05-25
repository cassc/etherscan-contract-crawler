// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "@rarible/royalties/contracts/LibPart.sol";
import "@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract WatcherMinter is ERC1155, RoyaltiesV2Impl {
  string public name;
  string public symbol;
  string public contractURI = "QmdqrVASguJRJHAzbfys3xdfbhLCTyKogGNyQiDQeNSgss";

  bytes32 public OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public ADMIN_ROLE = keccak256("ADMIN_ROLE");

  mapping(uint => string) public tokenURI;
  mapping(address => bool) public isAdmin;

  address public owner;
  address payable public royaltyAddress = payable(0x21ff1ac88a4A7c07C7573132f976D05B259632EE);

  constructor() ERC1155("") {
    name = "Frontier";
    symbol = "FRONTIER";

    owner = msg.sender;
  }

  modifier adminOnly() {
    require(msg.sender == owner || isAdmin[msg.sender] == true);
    _;
  }

  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }

  function addAdmin(address _address) external ownerOnly() {
    isAdmin[_address] = true;
  }

  function mint(address _to, uint _id, uint _amount) external adminOnly() {
    _mint(_to, _id, _amount, "");
  }

  function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external adminOnly() {
    _mintBatch(_to, _ids, _amounts, "");
  }

  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external adminOnly() {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }

  function setURI(uint _id, string memory _uri) external adminOnly() {
    require(bytes(tokenURI[_id]).length == 0);
    tokenURI[_id] = _uri;

    _setRoyalties(_id, royaltyAddress, 1000);

    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

  function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal adminOnly() {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    } 
}