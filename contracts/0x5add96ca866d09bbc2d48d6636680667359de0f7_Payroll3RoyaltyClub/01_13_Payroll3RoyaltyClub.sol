// SPDX-License-Identifier: MIT LICENSE
/*
 * @title Payroll3 Royalty Club
 * @author Marcus J. Carey, @marcusjcarey
 * @notice Payroll3 Royalty Club is a ERC-721 Token that allows
 * profit sharing transactions from the Payroll3 platform.
 */

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Payroll3RoyaltyClub is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public supply;

    bool private paused = false;
    address public payee;
    mapping(address => bool) public admins;
    uint256 public cost = 1 ether;
    uint256 public maxSupply = 100;

    string uriPrefix =
        'https://metaversable.mypinata.cloud/ipfs/QmWxgvAVDJzmMhGKU4WTgYpziCFGrQHGv4MVoyuwadSDnh/';
    string uriSuffix = '.json';

    constructor() ERC721('Payroll3 Royalty Club', 'P3RC') {
        admins[msg.sender] = true;
        payee = msg.sender;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], 'Sender not owner or admin.');
        _;
    }

    function addAdmin(address _address) public onlyAdmin {
        admins[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        admins[_address] = false;
    }

    function setPayee(address _payee) public onlyOwner {
        payee = _payee;
    }

    function mint() public payable {
        require(
            supply.current() < maxSupply,
            'Max supply has already been minted.'
        );
        require(msg.value >= cost, 'Payment is insufficient!');
        _safeMint(msg.sender, supply.current() + 1);
        emit Minted(msg.sender, supply.current() + 1);

        supply.increment();
    }

    function mintForAddress(address _address) public onlyAdmin {
        require(
            supply.current() < maxSupply,
            'Max supply has already been minted.'
        );

        _safeMint(_address, supply.current() + 1);
        emit Minted(msg.sender, supply.current() + 1);

        supply.increment();
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount &&
            currentTokenId <= supply.current()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function setCost(uint256 _cost) public onlyAdmin {
        cost = _cost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyAdmin {
        uriPrefix = _uriPrefix;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        return
            bytes(uriPrefix).length > 0
                ? string(
                    abi.encodePacked(uriPrefix, _tokenId.toString(), uriSuffix)
                )
                : '';
    }

    function withdraw() public onlyAdmin {
        (bool os, ) = payable(payee).call{value: address(this).balance}('');
        require(os);
    }

    function withdrawToken(address _address) external onlyAdmin {
        IERC20 token = IERC20(_address);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(payee, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {}

    event Received(address, uint256);
    event Minted(address _address, uint256 _id);
}