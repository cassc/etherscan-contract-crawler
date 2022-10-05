// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";


interface RICKHEAD {

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function batchFreeMint(address[] memory _winnerAddresses, uint64 amount)
    external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;
}

contract RickHeadTicket is ERC721A, Pausable, Ownable {


    enum SalePhase {
        Phase_Raffle,
        Phase_Public
    }

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum CouponType {
        PrivateWL,
        PublicWL
    }


    using Strings for uint256;

    SalePhase public phase = SalePhase.Phase_Raffle;


    uint256 public maxSupply = 1000;
    uint256 startRange = 100;
    // uint16 endRange = 1000;
    uint64 public mintPrice = 0.20 ether;
    bool public onlyClaim = true;


    address private rickHead_smartContract = 0x2890B33a94a4d5e6B29b80dCcDa385607833d211;
    address private crossMintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
    address private _adminSigner = 0xdf68A62aBB6B05C7b2b3BB8d1eF8898E4e3556D8;

    string private baseURI = "https://nft.dopedudes.xyz/api/metadata/ticket/";

    uint256[1001] public nftClaimed = [0];

    event NewURI(string newURI, address updatedBy);
    event WithdrawnPayment(uint256 balance, address owner);
    event updatePhase(SalePhase phase, uint64 price, address updatedBy);


    constructor() ERC721A("Rick Head Ticket", "RHT") {
    }
    
    /**
     * @dev setPhase updates the price and the phase to (Locked, Private, Presale or Public).
     $
     * Emits a {Unpaused} event.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setPhase(uint64 phasePrice_, SalePhase phase_)
    external
    onlyOwner {
        phase = phase_;
        mintPrice = phasePrice_;
        emit updatePhase(phase_, phasePrice_, msg.sender);
    }


    /**
     * @dev setBaseUri updates the new token URI in contract.
     *
     * Emits a {NewURI} event.
     *
     * Requirements:
     *
     * - Only owner of contract can call this function
     **/

    function setBaseUri(string memory uri)
    external
    onlyOwner {
        baseURI = uri;
        emit NewURI(uri, msg.sender);
    }

    /**
     * @dev Store claimed nft id in nftClaimed array
     * @param num value to store
     */
    function setClaimed(uint256 num) private {
        nftClaimed[num] = num;
    }



    function toggleOnlyClaim() external
    onlyOwner {
        onlyClaim = !onlyClaim;
    }
    /**
     * @dev Mint to mint ticket nft and get RickHead NFT
     *
     * Emits [Transfer] event.
     *
     * Requirements:
     *
     * - should have a valid coupon if we are ()
     **/

    function mint(
        uint256 amount, address to,
        Coupon memory coupon,
        CouponType couponType
    )
    external
    payable
    whenNotPaused
    verifyCoupon(coupon, couponType)
    {
        uint256 nextTokenId = _nextTokenId();
        require(!onlyClaim, "008");
        require(( maxSupply - startRange ) >= nextTokenId + amount, "error: 004" );
        require(msg.value >= amount * mintPrice, "error : 005");
        if (msg.sender != to)
            require(msg.sender == crossMintAddress, "error: 006");
        for (uint i = nextTokenId; i < amount; i++) {
            setClaimed(i);
        }

        address[] memory arrTo = new address[](1);
        arrTo[0] = address(to);
        _mint(to, amount);
        freeMint(arrTo,uint64(amount));
    }


    /**
     * @dev claim to mint ticket nft
     *
     * Emits [Transfer] event.
     *
     * Requirements:
     *
     * - should have a valid coupon if we are ()
     **/

    function claimTicket(uint64[] memory idsRickHead)
    external
    payable
    whenNotPaused
     {
        for (uint i = 0; i < idsRickHead.length; i++) {
            require(idsRickHead[i] >= 1, "error: 001");
            require(idsRickHead[i] <= startRange, "error: 001");
            require(nftClaimed[idsRickHead[i]] == 0, "error: 002");
            require(RICKHEAD(rickHead_smartContract).ownerOf(idsRickHead[i]) == msg.sender, "error: 003");
            setClaimed(idsRickHead[i]);
        }
        _mint(msg.sender, idsRickHead.length);
    }


    /**
     * @dev getbaseURI returns the base uri
     *
     */

    function getbaseURI() public view returns(string memory) {
        return baseURI;
    }

    /**
     * @dev tokenURI returns the uri to meta data
     *
     */

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns(string memory) {
        require(_exists(tokenId), "ERC721A: Query for non-existent token");
        return bytes(baseURI).length > 0 ?
        string(abi.encodePacked(baseURI, tokenId.toString())) :
        "";

    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    /**
     * @dev pause() is used to pause contract.
     *
     * Emits a {Paused} event.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     **/

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpause() is used to unpause contract.
     *
     * Emits a {Unpaused} event.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     **/

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev withdraw is used to withdraw payment from contract.
     *
     * Emits a {WithdrawnPayment} event.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     **/

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit WithdrawnPayment(balance, msg.sender);
    }


    function freeMint(address[] memory to,uint64 amount)internal {
        RICKHEAD(rickHead_smartContract).batchFreeMint(to,amount);
    }

    function transferDopDudeOwnership(address owner)public onlyOwner{
        RICKHEAD(rickHead_smartContract).transferOwnership(owner);
    }

    // function getAllNFTClaimed() public view returns (uint256[] memory){
    //     uint256[] memory ret = new uint256[](101);
    //     for (uint i = 0; i < 101; i++) {
    //         ret[i] = nftClaimed[i];
    //     }
    //     return ret;
    // }

    /**
     * @dev setCollectionAddress updates the address of the collection.
     *
     *
     * Requirements:
     *
     * - Only owner of contract can call this function
     **/

    function setCollectionAddress(address _address)
    external
    onlyOwner {
        rickHead_smartContract = _address;
    }


    function isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
    internal
    view
    returns(bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "016"); // Added check for zero address
        return signer == _adminSigner;
    }

    /**
    * @notice check coupon by coupon type
    */
    modifier verifyCoupon(Coupon memory coupon, CouponType couponType) {
        if(phase == SalePhase.Phase_Raffle){
            require(couponType == CouponType.PrivateWL, "007");
            bytes32 digest = keccak256(
            abi.encode(couponType, msg.sender)
            );
            require(isVerifiedCoupon(digest, coupon), "008");
             _;
        }
    }



 /**
     * @dev batchFreeMint 
     *
     * Requirements:
     *
     * - Only owner of contract can call this function
     **/
    function batchFreeMint(address[] memory _winnerAddresses, uint64 amount)
    external
    onlyOwner {
        uint256 nextTokenId = _nextTokenId();
        require(( maxSupply - startRange ) >= nextTokenId + amount, "error: 004" );
        for (uint i = 0; i < _winnerAddresses.length; i++) {
            for (uint256 j = 0; j < amount; j++) {
                _mint(_winnerAddresses[i], amount);
                address[] memory arrTo = new address[](1);
                arrTo[0] = address(_winnerAddresses[i]);
                freeMint( arrTo, uint64(amount));
            }
        }
    }

}