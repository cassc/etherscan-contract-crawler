// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract MetaDripsRefund is Ownable {
    address public nftAddress;
    address public burnerAddress;

    uint256[] public prices = [0, 0.5 ether, 1 ether, 3 ether];
    mapping(uint => uint) public tier;

    constructor(
        address _nftAddress,
        address _burnerAddress
    ) {
        nftAddress = _nftAddress;
        burnerAddress = _burnerAddress;
    }


    function refund(uint[] calldata _ids) public payable {
        uint256 amount = 0;
        for(uint i; i< _ids.length; i++) {
            amount += prices[tier[_ids[i]]];
            IERC721(nftAddress).transferFrom(msg.sender, burnerAddress, _ids[i]);
        }
        bool success = payable(msg.sender).send(amount);
        require(success, "Something went wrong");
    }


    function setIDs(uint _id, uint _tier) external onlyOwner() {
        tier[_id] = _tier;
    }

    function receiveETH() public payable {}

    function withdrawAll() external onlyOwner() {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}