// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

//     ___       ___       ___       ___       ___            ___       ___       ___       ___       ___       ___       ___       ___
//    /\__\     /\  \     /\__\     /\  \     /\__\          /\  \     /\  \     /\__\     /\__\     /\  \     /\  \     /\__\     /\  \
//   /::L_L_   /::\  \   |::L__L   /::\  \   /:| _|_        /::\  \   /::\  \   /:/  /    /:/  /    /::\  \   /::\  \   /:/ _/_   /::\  \
//  /:/L:\__\ /::\:\__\ /::::\__\ /:/\:\__\ /::|/\__\      /::\:\__\ /:/\:\__\ /:/__/    /:/__/    /:/\:\__\ /:/\:\__\ /::-"\__\ /\:\:\__\
//  \/_/:/  / \/\::/  / \;::;/__/ \:\/:/  / \/|::/  /      \:\::/  / \:\/:/  / \:\  \    \:\  \    \:\/:/  / \:\ \/__/ \;:;-",-" \:\:\/__/
//    /:/  /    /:/  /   |::|__|   \::/  /    |:/  /        \::/  /   \::/  /   \:\__\    \:\__\    \::/  /   \:\__\    |:|  |    \::/  /
//    \/__/     \/__/     \/__/     \/__/     \/__/          \/__/     \/__/     \/__/     \/__/     \/__/     \/__/     \|__|     \/__/
//

contract MaxonBollocks is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    // [...] 3888, to live forever, in eternal wealth, luck, love, and peace of mind.
    uint256 public constant COLLECTION_SIZE = 3888;

    // [...] There was always something new to make you hungry. Like the bard said, ‘Mo’ money mo’ problems.’
    uint256 public constant PRICE_PER_1  = 0.080 ether; // =  1 x 0.080
    uint256 public constant PRICE_PER_5  = 0.375 ether; // =  5 x 0.075
    uint256 public constant PRICE_PER_10 = 0.650 ether; // = 10 x 0.065
    uint256 public constant PRICE_PER_15 = 0.900 ether; // = 15 x 0.060
    uint256 public constant PRICE_PER_20 = 1.100 ether; // = 20 x 0.055

    // ‘Do you know what the 27 club is, Ben?’
    uint256 private _reserve = 27;

    // [...] booted it up, started work, feeling like a graverobber.
    bool    public  mintEnabled = false;

    string public MAXON_BOLLOCKS_PROVENANCE = "";
    string public baseURI = "https://maxon-bollocks.s3.us-west-1.amazonaws.com/m/";

    address _m = 0xC96E2bD9f505D1f1a2CF2abAa333c2DfA1378A21;

    constructor() ERC721("MaxonBollocks", "MXNBLKS") {}

    // setters & contract control
    function setProvenance(string memory provenance) public onlyOwner {
        MAXON_BOLLOCKS_PROVENANCE = provenance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function getReserveLeft() public view returns (uint256) {
        return _reserve;
    }

    // enable / disable minting
    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    // = return all Maxon originals owned by a certain address
    function maxonCollectionOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 count = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](count);
        for(uint256 i; i < count; i++){
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // = minting
    function mint(uint256 mintAmount) external payable {
        // mint must be enabled to continue
        require(mintEnabled, "Mint is not yet active.");

        // block mints from contracts
        require(msg.sender == tx.origin, "Reverted");

        // mint amount validation
        require(
            mintAmount == 1  ||
            mintAmount == 5  ||
            mintAmount == 10 ||
            mintAmount == 15 ||
            mintAmount == 20,
            "Can only mint one of the set amounts (1, 5, 10, 15 or 20)"
        );
        require(totalSupply().add(mintAmount) <= COLLECTION_SIZE - _reserve, "Not enough Maxon Bollocks left");

        // mint cost validation
        require(
            (mintAmount == 1  && msg.value >= PRICE_PER_1 ) ||
            (mintAmount == 5  && msg.value >= PRICE_PER_5 ) ||
            (mintAmount == 10 && msg.value >= PRICE_PER_10) ||
            (mintAmount == 15 && msg.value >= PRICE_PER_15) ||
            (mintAmount == 20 && msg.value >= PRICE_PER_20),
            "Incorrect ether value sent"
        );

        for(uint i = 0; i < mintAmount; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < COLLECTION_SIZE - _reserve) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // = reserve for a certain address
    function reserve(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount <= _reserve, "Not enough reserve left");

        uint current = totalSupply();
        for (uint i = 0; i < _amount; i++) {
            _safeMint(_to, current + i);
        }

        _reserve = _reserve - _amount;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawM() public onlyOwner {
        require(payable(_m).send(address(this).balance));
    }
}