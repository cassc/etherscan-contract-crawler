// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";


interface IStaking {
    function checkTokenStakedPeriodForUser(
        uint256 _tokenId,
        address _user
    ) external view returns (uint256);

    function claimReward(uint256 _tokenId, uint256 claimDays) external;
}

contract Materials is
    Initializable,
    ERC1155Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public constant BOOK_FISSION = 0;
    uint256 public constant BOOK_ENERGY = 1;
    uint256 public constant BOOK_WATER = 2;
    uint256 public constant URENIUM = 3;
    uint256 public constant METAL = 4;
    uint256 public constant H20 = 5;
    uint256 public constant HEAVY_WATER = 6;
    uint256 public constant TURBINE = 7;
    uint256 public constant REACTOR = 8;
    uint256 public constant MATERPIECE_REACTOR = 9;

    uint256[] public books_supply;
    uint256[] public books_minted;
    uint256[] public books_price;

    // material stake days
    uint256[] public STAKE_DAYS;
    mapping(uint256 => bool) public nft_book;
    IERC20Upgradeable public tokenAddress;
    bytes32 merketRootAddress; // address of merkle root

    // stages for claiming book
    uint256 public stage;
    address public stakingAddress;
    mapping(bytes32 => RequestStatus) public requestStatuses;
    mapping(address => bytes32) public userRequestIds;
    // random number, claimed, user
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256 number;
        address user;
        bool claimed;
    }

    function initialize(
        bytes32 _merketRootAddress,
        string memory _uri,
        address _stakingAddress,
        address _tokenAddress,
        uint256[] memory _books_supply,
        uint256[] memory _books_price,
        uint256[] memory _books_minted,
        uint256[] memory _STAKE_DAYS,
        uint256 _mintinfStage
    ) public initializer {
        __ERC1155_init(_uri);
        __Ownable_init();
        __Pausable_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();

        merketRootAddress = _merketRootAddress;
        stakingAddress = _stakingAddress;
        tokenAddress = IERC20Upgradeable(_tokenAddress);
        books_supply = _books_supply;
        books_price = _books_price;
        books_minted = _books_minted;
        STAKE_DAYS = _STAKE_DAYS;
        stage = _mintinfStage;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setStakingAddress(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = IERC20Upgradeable(_tokenAddress);
    }

    function setBookPrice(uint256 _book, uint256 _price) public onlyOwner {
        books_price[_book] = _price;
    }

    function setBookSupply(uint256 _book, uint256 _supply) public onlyOwner {
        books_supply[_book] = _supply;
    }

    function setStage(uint256 _stage) public onlyOwner {
        stage = _stage;
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // update the uri
    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function _mintBook(address _user, uint256 _bookIds) internal {
        books_minted[_bookIds] += 1;
        _mint(_user, _bookIds, 1, "");
    }

    // mint books batch
    function _mintBooks(address _user, uint256[] memory _bookIds) internal {
        // check book has not exhausted
        uint256[] memory bookIdAmounts = new uint256[](_bookIds.length);

        for (uint256 i = 0; i < _bookIds.length; i++) {
            books_minted[_bookIds[i]] += 1;
            bookIdAmounts[i] = 1;
        }

        _mintBatch(_user, _bookIds, bookIdAmounts, "");
    }

    // get unclaimed books
    function getUnclaimedBooks(
        uint256[] memory nfts_
    ) public view returns (uint256[] memory) {
        uint256[] memory unclaimedBooks = new uint256[](nfts_.length);

        for (uint256 i = 0; i < nfts_.length; i++) {
            if (nft_book[nfts_[i]] != true) {
                unclaimedBooks[i] = nfts_[i];
            }
        }
        return unclaimedBooks;
    }

    // claim single book validating markel for each nft and book id
    function claimBookWithProof(
        uint256 _bookId,
        uint256 _nftId,
        bytes32[] memory _proof
    ) public {
        require(stage == 1, "Claiming is not allowed");
        require(nft_book[_nftId] != true, "You have already claimed this book");

        // check if user has staked for all nfts
        require(
            IStaking(stakingAddress).checkTokenStakedPeriodForUser(
                _nftId,
                msg.sender
            ) > 0,
            "User has not staked this nft"
        );

        string memory booknftID = string(
            abi.encodePacked(_bookId.toString(), _nftId.toString())
        );

        require(
            MerkleProofUpgradeable.verify(
                _proof,
                merketRootAddress,
                keccak256(abi.encodePacked(booknftID))
            ),
            "Invalid proof"
        );

        nft_book[_nftId] = true;
        require(
            books_minted[_bookId] < books_supply[_bookId],
            "This book supply has been exhausted"
        );
        _mintBook(msg.sender, _bookId);

        // update user request status
    }

    // claim books validating markel for each nft and book id
    function claimBooksWithProof(
        uint256[] memory _bookIds,
        uint256[] memory _nftIds,
        bytes32[][] memory _proofs
    ) public {
        require(stage == 1, "Claiming is not allowed");
        require(_bookIds.length == _nftIds.length, "Invalid input");
        require(_bookIds.length == _proofs.length, "Invalid input");

        // check if user has already claimed
        require(
            requestStatuses[userRequestIds[msg.sender]].claimed == false,
            "User has already claimed"
        );

        // check if user has staked for all nfts
        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(
                IStaking(stakingAddress).checkTokenStakedPeriodForUser(
                    _nftIds[i],
                    msg.sender
                ) > 0,
                "User has not staked this nft"
            );
        }
        string[] memory booksnftsIDS = new string[](_bookIds.length);

        for (uint256 i = 0; i < _bookIds.length; i++) {
            booksnftsIDS[i] = string(
                abi.encodePacked(_bookIds[i].toString(), _nftIds[i].toString())
            );
        }

        // verify merkel proof agains each element of booksnftsIDS
        for (uint256 i = 0; i < booksnftsIDS.length; i++) {
            require(
                nft_book[_nftIds[i]] != true,
                "You have already claimed this book"
            );

            require(
                MerkleProofUpgradeable.verify(
                    _proofs[i],
                    merketRootAddress,
                    keccak256(abi.encodePacked(booksnftsIDS[i]))
                ),
                "Invalid proof"
            );
            require(
                books_minted[_bookIds[i]] < books_supply[_bookIds[i]],
                "This book supply has been exhausted"
            );
            nft_book[_nftIds[i]] = true;
        }
        _mintBooks(msg.sender, _bookIds);
    }

    // get price of book
    function getBookPrice(uint256 bookId_) public view returns (uint256) {
        return books_price[bookId_];
    }

    // claim material from stake
    function claimMaterial(
        uint256 _nftId,
        uint256 _meterial
    ) public whenNotPaused {
        // clamin non book nft
        require(_meterial >= 3, "Invalid material");
        // stage shoukd be 2
        require(stage == 2, "Claiming material is not available");
        // check if nft has been staked
        IStaking staking = IStaking(stakingAddress);
        uint256 time = staking.checkTokenStakedPeriodForUser(
            _nftId,
            msg.sender
        );
        // time must be greater then meterial stake days
        uint256 materiaStakeIndex = _meterial - 3;
        require(
            time >= STAKE_DAYS[materiaStakeIndex],
            "NFT has not been staked for enough days"
        );
        staking.claimReward(_nftId, STAKE_DAYS[materiaStakeIndex]);
        _mint(msg.sender, _meterial, 1, "");
    }

    function claimMaterials(
        uint256[] memory _nftIds,
        uint256 _meterial
    ) public whenNotPaused {
        // clamin non book nft
        require(_meterial >= 3, "Invalid material");
        // stage shoukd be 2
        require(stage == 2, "Claiming material is not available");
        // check if nft has been staked
        IStaking staking = IStaking(stakingAddress);
        uint256[] memory nftIds = new uint256[](_nftIds.length);
        for (uint256 i = 0; i < _nftIds.length; i++) {
            uint256 time = staking.checkTokenStakedPeriodForUser(
                _nftIds[i],
                msg.sender
            );
            // time must be greater then meterial stake days
            uint256 materiaStakeIndex = _meterial - 3;
            require(
                time >= STAKE_DAYS[materiaStakeIndex],
                "NFT has not been staked for enough days"
            );
            nftIds[i] = _nftIds[i];
            staking.claimReward(nftIds[i], STAKE_DAYS[materiaStakeIndex]);
        }
        _mint(msg.sender, _meterial, _nftIds.length, "");
    }

    // fussion reactor
    function fissionReactor(uint256 _amount) public whenNotPaused {
        // this need to burn 6 metals and 2 uranium
        // check if user has 6 metals and 2 uranium
        require(
            tokenAddress.balanceOf(msg.sender) >= 1 * 10 ** 18,
            "You do not have enough $PIXAPE tokens"
        );
        require(_amount > 0, "Invalid amount");

        require(
            balanceOf(msg.sender, METAL) >= 6 * _amount,
            "You do not have enough metals"
        );
        require(
            balanceOf(msg.sender, URENIUM) >= 2 * _amount,
            "You do not have enough uranium"
        );

        // user must also have 1 enegy book
        require(
            balanceOf(msg.sender, BOOK_ENERGY) >= 1,
            "You do not have enough energy book"
        );
        tokenAddress.transferFrom(
            msg.sender,
            address(this),
            _amount * 10 ** 18
        );

        // burn 6 metals and 2 uranium
        _burn(msg.sender, METAL, 6 * _amount);
        _burn(msg.sender, URENIUM, 2 * _amount);
        // mint 1 reactor
        _mint(msg.sender, REACTOR, _amount, "");
    }

    // reuffle claim with vrf

    // fission turbine
    function fissionTurbine(uint256 _amount) public whenNotPaused {
        // this need to burn 6 metals 2 heavy water and 2 H20
        // check if user has 6 metals and 2 heavy water and 2 water
        // should pay 1 pixape token
        require(
            tokenAddress.balanceOf(msg.sender) >= 1 * 10 ** 18,
            "You do not have enough $PIXAPE tokens"
        );
        // amount should be more than 0
        require(_amount > 0, "Invalid amount");

        // transfer tokens to contract
        require(
            balanceOf(msg.sender, METAL) >= 6 * _amount,
            "You do not have enough metals"
        );
        require(
            balanceOf(msg.sender, HEAVY_WATER) >= 2 * _amount,
            "You do not have enough heavy water"
        );
        require(
            balanceOf(msg.sender, H20) >= 6 * _amount,
            "You do not have enough water"
        );

        // user must also have 1 water book
        require(
            balanceOf(msg.sender, BOOK_WATER) >= 1,
            "You do not have enough water book"
        );
        tokenAddress.transferFrom(
            msg.sender,
            address(this),
            _amount * 10 ** 18
        );
        // burn 6 metals and 2 heavy water and 2 water
        _burn(msg.sender, METAL, 6 * _amount);
        _burn(msg.sender, HEAVY_WATER, 2 * _amount);
        _burn(msg.sender, H20, 6 * _amount);

        // mint 1 turbine
        _mint(msg.sender, TURBINE, _amount, "");
    }

    // craft master piece
    function craftMasterPiece(uint256 _amount) public whenNotPaused {
        /* 
        YOU NEED 
            5 REACTOR
            5 TURBINE
            30 uranium
            50 metals
            5 heavy water
            15 water
            1 BOOK_FISSION
            100 tokens
        */

        //    chexck user has enough erc20 tokens
        require(
            tokenAddress.balanceOf(msg.sender) >=
                (5 * _amount) * 10 ** 18 * 10 ** 18,
            "You do not have enough $PIXAPE tokens"
        );
        require(_amount > 0, "Invalid amount");

        // transfer tokens to contract

        // check if user has 5 reactor
        require(
            balanceOf(msg.sender, REACTOR) >= 5 * _amount,
            "You do not have enough reactor"
        );
        // check if user has 5 turbine
        require(
            balanceOf(msg.sender, TURBINE) >= 5 * _amount,
            "You do not have enough turbine"
        );
        // check if user has 30 uranium
        require(
            balanceOf(msg.sender, URENIUM) >= 30 * _amount,
            "You do not have enough uranium"
        );
        // check if user has 50 metals

        require(
            balanceOf(msg.sender, METAL) >= 50 * _amount,
            "You do not have enough metals"
        );
        // check if user has 5 heavy water
        require(
            balanceOf(msg.sender, HEAVY_WATER) >= 5 * _amount,
            "You do not have enough heavy water"
        );
        // check if user has 15 water
        require(
            balanceOf(msg.sender, H20) >= 15 * _amount,
            "You do not have enough water"
        );
        // check if user has 1 book fission
        require(
            balanceOf(msg.sender, BOOK_FISSION) >= 1,
            "You do not have enough fission book"
        );

        tokenAddress.transferFrom(
            msg.sender,
            address(this),
            (5 * _amount) * 10 ** 18
        );
        // burn 5 reactor
        _burn(msg.sender, REACTOR, 5 * _amount);
        // burn 5 turbine
        _burn(msg.sender, TURBINE, 5 * _amount);
        // burn 30 uranium
        _burn(msg.sender, URENIUM, 30 * _amount);
        // burn 50 metals
        _burn(msg.sender, METAL, 50 * _amount);
        // burn 5 heavy water
        _burn(msg.sender, HEAVY_WATER, 5 * _amount);
        // burn 15 water
        _burn(msg.sender, H20, 15 * _amount);
        // mint 1 master piece
        _mint(msg.sender, MATERPIECE_REACTOR, _amount, "");
    }
}