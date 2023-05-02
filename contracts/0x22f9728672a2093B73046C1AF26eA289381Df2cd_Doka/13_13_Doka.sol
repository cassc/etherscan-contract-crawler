// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A} from "erc721a/ERC721A.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {ERC2981} from "openzeppelin/token/common/ERC2981.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

contract Doka is ERC721A, Ownable, ERC2981, OperatorFilterer {
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrInvalidValue();
    error ErrReserveClosed();
    error ErrWLIsClosed();
    error ErrMintZero();
    error ErrExceedsMaxPerWallet();
    error ErrExceedsMaxPerTransaction();
    error ErrExceedsSupply();
    error ErrInvalidSignature();
    error ErrMintDisabled();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EvReserve(address indexed sender, uint256 amount, uint256 value);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant TEAM_ADDRESS = 0x4797cA0eF1572dfE1a49E16A6D5481FdB526be41;
    address constant PROCEEDS_ADDRESS = 0x945eDE0F6eAd8137c03eA4b3c3B417bebB805Be7;
    uint256 constant MAX_SUPPLY = 5555;
    uint256 constant RESERVED_SUPPLY = 5455;
    uint256 constant FCFS_SUPPLY = 500;
    uint256 constant WL_SUPPLY = RESERVED_SUPPLY - FCFS_SUPPLY;
    uint256 constant MAX_PER_WL_WALLET = 2;
    uint256 constant MAX_PER_WL_TRANSACTION = 2;
    uint256 constant MAX_PER_PUBLIC_WALLET = 1;
    uint256 constant MAX_PER_PUBLIC_TRANSACTION = 1;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    // signer
    address internal $signer;

    // erc721
    string internal $baseURI;

    // reservation phase
    enum Phase {
        closed,
        wl,
        pub
    }

    Phase internal $phase;

    // price
    uint256 internal $reservePrice = 0.088 ether;

    // counter
    mapping(address => uint256) internal $reserveCounter;

    struct Counter {
        uint16 total;
        uint16 wl;
        uint16 pub;
        uint16 fcfs;
    }

    Counter internal $counter;

    // reservations
    struct Reservation {
        address addr;
        bool isWL;
        uint8 amount;
    }

    Reservation[] internal $wlReservations;
    Reservation[] internal $publicReservations;
    Reservation[] internal $fcfsReservations;

    // mint
    bool internal $mintEnabled = true;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address signer_) ERC721A("Doka", "DOKA") {
        // initial states
        $signer = signer_;

        // init operator filtering
        _registerForOperatorFiltering();

        // set initial royalty - 5%
        _setDefaultRoyalty(TEAM_ADDRESS, 500);
    }

    /* -------------------------------------------------------------------------- */
    /*                              operator filterer                             */
    /* -------------------------------------------------------------------------- */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Both safeTransferFrom functions in ERC721A call this function
     * so we don't need to override them.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc2981                                  */
    /* -------------------------------------------------------------------------- */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc165                                   */
    /* -------------------------------------------------------------------------- */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc721a                                  */
    /* -------------------------------------------------------------------------- */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return $baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function reserve(uint256 amount_, bool isWL_, bytes calldata signature_) external payable {
        // input checks
        if (amount_ == 0) revert ErrMintZero();
        if (isWL_) {
            if (amount_ > MAX_PER_WL_TRANSACTION) revert ErrExceedsMaxPerTransaction();
        } else {
            if (amount_ > MAX_PER_PUBLIC_TRANSACTION) revert ErrExceedsMaxPerTransaction();
        }

        // read states
        uint256 __reservePrice = $reservePrice;
        uint256 __count = $reserveCounter[msg.sender];
        Phase __phase = $phase;
        Counter memory __counter = $counter;
        address __signer = $signer;

        // checks
        if (__phase == Phase.closed) revert ErrReserveClosed(); // phase
        if (__phase != Phase.wl && isWL_) revert ErrWLIsClosed(); // phase
        if (msg.value != amount_ * __reservePrice) revert ErrInvalidValue(); // value
        if (isWL_) {
            if (__count + amount_ > MAX_PER_WL_WALLET) revert ErrExceedsMaxPerWallet(); // maxPerWallet
        } else {
            if (__count + amount_ > MAX_PER_PUBLIC_WALLET) revert ErrExceedsMaxPerWallet(); // maxPerWallet
        }

        // check signature
        if (isWL_) {
            // check signature
            bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount_, isWL_));
            bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
            if (ECDSA.recover(ethHash, signature_) != __signer) revert ErrInvalidSignature();
        }

        // check supply
        // - whitelist
        if (isWL_) {
            if (__counter.wl + __counter.fcfs + amount_ > RESERVED_SUPPLY) {
                revert ErrExceedsSupply();
            }
        }
        // - public
        else {
            if (__counter.total + amount_ > RESERVED_SUPPLY) revert ErrExceedsSupply();
        }

        // update
        // - reserveCounter
        $reserveCounter[msg.sender] = __count + amount_;

        // - addresses array & counter
        uint16 __amount16 = uint16(amount_);

        // wl
        if (isWL_) {
            // has space in wl
            if (__counter.wl < WL_SUPPLY) {
                uint256 __availableWL = WL_SUPPLY - __counter.wl;
                // enough space in wl for all
                if (amount_ <= __availableWL) {
                    $wlReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(amount_)}));
                    __counter.wl += __amount16;
                }
                // split into wl & fcfs
                else {
                    // wl
                    $wlReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(__availableWL)}));
                    __counter.wl += uint16(__availableWL);

                    // fcfs
                    uint256 __fcfsAmount = amount_ - __availableWL;
                    $fcfsReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(__fcfsAmount)}));
                    __counter.fcfs += uint16(__fcfsAmount);
                }
            }
            // all fcfs
            else {
                $fcfsReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(amount_)}));
                __counter.fcfs += __amount16;
            }
        }
        // public
        else {
            // has space in fcfs
            if (__counter.fcfs < FCFS_SUPPLY) {
                uint256 __availableFCFS = FCFS_SUPPLY - __counter.fcfs;
                // enough space in fcfs for all
                if (amount_ <= __availableFCFS) {
                    $fcfsReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(amount_)}));
                    __counter.fcfs += __amount16;
                }
                // split into fcfs & public
                else {
                    // fcfs
                    $fcfsReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(__availableFCFS)}));
                    __counter.fcfs += uint16(__availableFCFS);

                    // public
                    uint256 __pubAmount = amount_ - __availableFCFS;
                    $publicReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(__pubAmount)}));
                    __counter.pub += uint16(__pubAmount);
                }
            }
            // all public
            else {
                $publicReservations.push(Reservation({addr: msg.sender, isWL: isWL_, amount: uint8(amount_)}));
                __counter.pub += __amount16;
            }
        }

        __counter.total += __amount16;
        $counter = __counter;

        emit EvReserve(msg.sender, amount_, msg.value);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setSigner(address signer_) external onlyOwner {
        $signer = signer_;
    }

    function setPhase(Phase phase_) external onlyOwner {
        $phase = phase_;
    }

    function setReservePrice(uint256 reservePrice_) external onlyOwner {
        $reservePrice = reservePrice_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        $baseURI = baseURI_;
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        address _wallet = PROCEEDS_ADDRESS;
        uint256 _payable = balance;
        payable(_wallet).transfer(_payable);
    }

    // airdrop
    struct Holder {
        address addr;
        uint256 amount;
    }

    function airdrop(Holder[] calldata holders_) external onlyOwner {
        if (!$mintEnabled) {
            revert ErrMintDisabled();
        }

        for (uint256 i = 0; i < holders_.length;) {
            Holder memory __holder = holders_[i];
            _mint(__holder.addr, __holder.amount);
            unchecked {
                ++i;
            }
        }

        if (_totalMinted() > MAX_SUPPLY) {
            revert ErrExceedsSupply();
        }
    }

    // stop
    function stopMint() external onlyOwner {
        $mintEnabled = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function signer() external view returns (address) {
        return $signer;
    }

    function phase() external view returns (Phase) {
        return $phase;
    }

    function reservePrice() external view returns (uint256) {
        return $reservePrice;
    }

    function baseURI() external view returns (string memory) {
        return $baseURI;
    }

    function totalReserveCounter() external view returns (uint256) {
        return $counter.total;
    }

    function wlReserveCounter() external view returns (uint256) {
        return $counter.wl;
    }

    function publicReserveCounter() external view returns (uint256) {
        return $counter.pub;
    }

    function fcfsReserveCounter() external view returns (uint256) {
        return $counter.fcfs;
    }

    function wlReservations() external view returns (Reservation[] memory) {
        return $wlReservations;
    }

    function publicReservations() external view returns (Reservation[] memory) {
        return $publicReservations;
    }

    function fcfsReservations() external view returns (Reservation[] memory) {
        return $fcfsReservations;
    }

    function reserveCounter(address addr) external view returns (uint256) {
        return $reserveCounter[addr];
    }

    function mintEnabled() external view returns (bool) {
        return $mintEnabled;
    }
}