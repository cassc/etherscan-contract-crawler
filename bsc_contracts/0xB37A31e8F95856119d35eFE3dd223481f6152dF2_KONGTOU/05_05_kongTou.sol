// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract KONGTOU {
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    modifier notAddress(address _useAdd) {
        require(_useAdd != address(0), "address is error");
        _;
    }

    event Received(address, uint);

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function pay() public payable {}

    function transferEthsAvg(
        address[] memory _tos
    ) public payable onlyOwner returns (bool) {
        require(_tos.length > 0);

        uint oneValue = address(this).balance / _tos.length;

        for (uint i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            payable(_tos[i]).transfer(oneValue);
        }

        return true;
    }

    function setOwner(address _ownerAddress) external onlyOwner {
        owner = _ownerAddress;
    }

    function transferEths(
        address[] memory _tos,
        uint256[] memory _values
    ) public payable onlyOwner returns (bool) {
        require(_tos.length > 0);
        require(_tos.length == _values.length);

        for (uint32 i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            require(_values[i] > 0);
            payable(_tos[i]).transfer(_values[i]);
        }

        return true;
    }

    function transferEth(address _to) public payable onlyOwner returns (bool) {
        require(_to != address(0));
        require(msg.value > 0);

        payable(_to).transfer(msg.value);

        return true;
    }

    function checkBalance() public view returns (uint) {
        return address(this).balance;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function transferTokensAvg(
        address from,
        address _constractAdd,
        address[] memory _tos,
        uint _v
    ) external {
        require(_tos.length > 0);
        require(_v > 0);

        IERC20 _token = IERC20(_constractAdd);

        //要调用的方法id进行编码
        // bytes4 methodId = bytes4(keccak256("transferFrom(address,address,uint256)"));

        for (uint i = 0; i < _tos.length; i++) {
            _token.transferFrom(from, _tos[i], _v);
            // _constractAdd.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",from,_tos[i],_v));
            // _constractAdd.call(methodId,from,_tos[i],_v);
        }
    }

    function transferTokens(
        address from,
        address _constractAdd,
        address[] memory _tos,
        uint[] memory _values
    ) public onlyOwner notAddress(from) returns (bool) {
        require(_tos.length > 0);
        require(_values.length > 0);
        require(_values.length == _tos.length);

        bool status;
        bytes memory msgs;

        //要调用的方法id进行编码
        // bytes4 methodId = bytes4(keccak256("transferFrom(address,address,uint256)"));

        for (uint i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            require(_values[i] > 0);

            (status, msgs) = _constractAdd.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    from,
                    _tos[i],
                    _values[i]
                )
            );
            require(status == true);

            // require(_constractAdd.call(methodId,from,_tos[i],_values[i]));
        }

        return true;
    }

    function transferTokenOne(
        address _from,
        address _constractAdd,
        address _to,
        uint _tokenId
    )
        public
        notAddress(_from)
        notAddress(_constractAdd)
        notAddress(_to)
        onlyOwner
        returns (bool)
    {
        IERC721 _token = IERC721(_constractAdd);
        _token.safeTransferFrom(_from, _to, _tokenId);
        return true;
    }

    function transferToken1155(
        address _from,
        address _contractAdd,
        address _to,
        uint _tokenId,
        uint _num
    )
        public
        notAddress(_from)
        notAddress(_contractAdd)
        notAddress(_to)
        returns (bool)
    {
        IERC1155 _token = IERC1155(_contractAdd);
        _token.safeTransferFrom(_from, _to, _tokenId, _num, "");
        return true;
    }

    function transferTokenBatch1155(
        address _from,
        address _contractAdd,
        address _to,
        uint[] memory _tokenIds,
        uint[] memory _nums
    )
        public
        notAddress(_from)
        notAddress(_contractAdd)
        notAddress(_to)
        returns (bool)
    {
        IERC1155 _token = IERC1155(_contractAdd);
        _token.safeBatchTransferFrom(_from, _to, _tokenIds, _nums, "");
        return true;
    }
}