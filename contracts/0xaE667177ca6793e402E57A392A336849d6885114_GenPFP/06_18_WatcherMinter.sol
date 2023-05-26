// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract WatcherMinter is ERC1155 {
    string public name;
    string public symbol;
    // string public contractURI = "QmdqrVASguJRJHAzbfys3xdfbhLCTyKogGNyQiDQeNSgss";

    bytes32 public OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint256 => string) public tokenURI;
    mapping(address => bool) public isAdmin;

    address public owner;

    constructor() ERC1155("") {
        // name = "Frontier";
        // symbol = "FRONTIER";

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

    function addAdmin(address _address) external ownerOnly {
        isAdmin[_address] = true;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external adminOnly {
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external adminOnly {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external adminOnly {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint256 _id, string memory _uri) external adminOnly {
        require(bytes(tokenURI[_id]).length == 0);
        tokenURI[_id] = _uri;

        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }
}