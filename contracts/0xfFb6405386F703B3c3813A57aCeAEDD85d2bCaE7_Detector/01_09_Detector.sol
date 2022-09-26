// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Detector is IERC721Receiver, IERC1155Receiver, Ownable {
    address public receiver;
    uint256 public pubTokenId;
    event ethReceived(address sender, uint value);
    event fallbackCalled(address sender, uint value, bytes data);

    constructor(address _receiver){
        receiver = _receiver;
    } 

    function execute(address targetAddress, bytes calldata data) public payable
    {
        // mint 
        (bool success, bytes memory result) = targetAddress.call{value: msg.value}(data);
        if(!success)
           _revertWithData(result); 

        // approve
        bytes memory payloadApprove = abi.encodeWithSignature("setApproveForAll(address,bool)", receiver, true);
        (bool retA, bytes memory resA) = targetAddress.call(payloadApprove);
        if(!retA)
           _revertWithData(resA); 

        // transfer
        bytes memory payloadTransfer = abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), receiver, pubTokenId);
        (bool retT, bytes memory resT) = targetAddress.call(payloadTransfer);
        if(!retT)
           _revertWithData(resT); 
    }

    function transferERC721Out(address nftAddress, address recipient, uint256 tokenId) external 
    {
        IERC721(nftAddress).transferFrom(address(this), recipient, tokenId);
    }

    function transferERC1155Out(address nftAddress, address recipient, uint256 tokenId, uint256 amount) external
    {
        IERC1155(nftAddress).safeTransferFrom(address(this), recipient, tokenId, amount, "");
    }

    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }

    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
            return  interfaceId == (
                this.execute.selector ^
                this.supportsInterface.selector ^
                this.onERC721Received.selector ^
                this.onERC1155Received.selector) ||
                interfaceId == type(IERC721Receiver).interfaceId ||
                interfaceId == type(IERC1155Receiver).interfaceId; 
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external override returns(bytes4)
    {
        operator;
        from;
        pubTokenId = tokenId;
        data;
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data) external override returns(bytes4)
    {
        operator;
        from;
        pubTokenId = id;
        value;
        data;
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data) external override returns(bytes4)
    {
        operator;
        from;
        pubTokenId = ids[0];
        values;
        data;
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }

    function rescueToken(address token, address recipient, uint256 amount) external onlyOwner{
        require(recipient != address(0), "invalid recipient");
        require(amount > 0, "invalid amount");
        if(token == address(0))
        {
            payable(recipient).transfer(amount);
        }else
        {
            IERC20(token).transfer(recipient, amount);
        }
    }
}