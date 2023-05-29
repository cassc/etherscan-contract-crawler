//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ONFT721} from "../Omnichain/token/onft/ONFT721.sol";

/**
                                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                          
                            .....::::::::....                                                 .::^~~~~!!!!!!!!!~:.                                                                                                                                        
                     .:~!77?????JJ???JJJJJJJ???7!~^:.                                     :~!???????777777777??JYJ7^                                                                                                                                      
                   :7??7!~~~^^^^^^^^^^^^~~~~!!77?JJJJ?!:.                               :7J?!^::........::::::^~7JYY7:::::..                                                                                                                              
                  ~J?~:...................:::::^^^~!7?YYJ7^.                           :JJ~:...................:^7JY5YYYYYYJ7^.       ...       .^~~~~^.                                                               ..:::::..                          
                 ^Y?^...........................:::^^^~7?YY?^.     .:^~!77??7777!~^:. .?J!.....................:^7JJ7!~~!?Y55YJ^  :!7??JJ?7~..~???7??JYY?^            ...:...          .:^~~^:.         .:^~~~~:.  .^!7????JJJJJ??!^.                     
                 7Y?:...............................::^^~!JYY?: :~7??77!!~~!!!77?JJJJ?7Y?^.....................^7J7:.....:~JYYYY~7J7~^^~!?YYJJJ!:..:^~7JYY7.     .^!7????JJJJ??!~:   :!?????JYJ?~.    .~??????JYJ77??!~^::::^^~!7?YYJ~                    
                 !YJ!:.................................:^^~?Y5J7J?~::..........::^~!7JYY?:........:^~~~~!!!!!!7JYY^.......:7YYYYYJ!.....:^!JYY7......^^7JY5!  .~7??!~~^^^^^~!!?JYYJ!!J?^:.::^!?Y5J!. :?J!:..:^~7JY?^............:^7JY5!                   
                 .?5Y?!~^^^^~~..........:~~^^:..........:^^~?YYJ~...........::.....:^~7J7:.......^^7JYYYYYYYYYYYYY?:.....:!YYYYYY7:......^^7J?:......:^~?YYJ^!J?!:..........::^^~7JYY?^......:^!?JYY!?Y7......:^?!:..............:!JYYJ:                  
                  .!J5YYYYYYJ?........:^~?YYJJ7!^........:^^!JJ~.........:~7J?!.....:^~?7:.......^^~!!!!!!!!?JYYYYYJ!~~~!JYYYYYYJ~.......:^~?^........^^7JYYY?~................::^~7J?^........:^~7JYYY7......:^7:.......::::...:!?YY5?.                  
                    .^7?JYYYY?........:^^7YYYYYY?^.......:^^!?7:........:^7JYY?:.....^^77:................::^~7YY?7~~^^~7?JYYYYY7:........:^^.........:^!?YY?^.........:::.......:^^7?^..........:^~7JY7......:^7:......:~7?????JYYYYJ:                   
                        ..:?Y?........:^^7YYYYJ?~........:^^!?~.........:^7YYJ!.....:^~??:...................:!??!:.....:~7?YYYJ~......................^^7J?^........^7?JJ?!:.....:^^7^............::~77:.....:^7!........:^~7?JYYYY!.                    
                           7Y?:.......:^^7JJ?7~:.........^^~?J~.........:^~!~^.....:^~?Y?:...................:!??^.......:!?YYY7:......................:^!?!.......:!JYY5YYY?:.....^^!^...............:^......:^7?!:.........::^!?JYJ!:                   
                      .^~!7JY?:.......:^^~~::...........:^~7JJ~..................:^~7JYY?^..................^!JJ?^.......^!?YYJ~........................^^?!.......^?YYY7:!YJ^.....:^~^......:^:..............:^7JY?~:..........:^~?Y5J~                  
                    :7??7!!~~~..........................^~?YYY!..............::~!7?JYYYYJ~.........^!!!777??JYYJ?^.......^7?YY7.......::................:^!!........!JY57~?J!:.....^^7^......^!?!^............:^7JYYYJ?!^:........:^7JYY~                 
                   !J?^:..............................:~7JYYYY?:..........^7?JJ7!~^^^!7J?~.........~JYYY5555YYYJ?^.......^7?Y?^.....:^~7:........^~.....:^^7^........^!7?7!^......:^~?~......^!?YJ7^..........:^7JYJ???J??7~:......:~?YYJ:                
                  ^Y?:..............................:~7JYY5YJYJ!...........!JJ!:.....:~?J~.........^?YYY7!~~~^YJ?^.......^7?J7......^^7?!.......:7?:.....:^!?^...................:^~??~......^!?YYYJ7^........:^7?!^::::^^^^:......:~?YYY^                
                  ?Y7:..........................:^~7?YY55Y7^.?5J!:..........::.......^!JJ!.........^?YYY^    :YJ?:.......^7??^.....:^~?YJ!:...:^7JJ~.....:^^??!:................:~7JYJ~......^!JYYYYYJ7^......:^7!.................:7JYYY:                
                  !5J!:...................::^~!7?JYY55Y?!:   .?5Y?!^...............:~7JYY?^.......:!JYYY^    :YJ?^.......~???^.....^^7JYYYJ??7?JYYY7:.....:^!JY?!^:...........^~7JYYYJ~......^!JYYY~7Y5J?~:..:~7J7:...............^7JYY57.                
                  .?5Y?!~^^:^^^^^^^~~!!77?JJYYY55YYJ7~:       .!Y5YJ?!~~^^^:^^^~~!7JJYYY5YJ7~^^^^!?YYY57.    .JYJ?~:::::~7JYY?~^::^~7JYYYJY55555YYYJ~.....^~7JYYYYJ7!~~^^~~!7?JYY55YYYJ!^:::~7JYY5J. :7Y5YJ??JJYYY?!^^:::::::::^!?JYYYY7.                 
                   .!J55YYYYYYYYYYYYYY55555YYJJ7!^:.            .~?YY5YYYYYYYYYYY5555YJ7~?Y5YYYYYY555J~.      :?5YJJ????JYYY55YJJJJYYY5Y7.:^~~~^::J5J7!~~!7?YYYY?JY55YYYYYYY555YY?!:^J5YYJJJJYY5Y?:    :!JYYYYYYJJ5YYYJJJJJJJJJYY55YY7^                   
                     .^!?JJJJJJJJJJJ??77!~~::.                     .^!7??JJJJJJJ??7!~:.   :!?JJJJJ?!^.         .~?YY555555YJ!~?JYYYYY?!:          :7Y55YYYY55YJ~ .:~!7??JJ???7~^:    .~?JYYYYYJ7^.        .:::::..~7?JYYYY5YYYYYJ?7^.                     
                         ...........                                     ........            .....                :^~!!!!^:.   .::::.               :~7?JJ??!^.         ..              ..::::.                      ..:::^^^^::.                         
                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                          
 */
contract DefimonsApartments is ONFT721 {
    //
    // Using Statements
    //

    using MerkleProof for bytes32[];
    using SafeERC20 for IERC20;

    //
    // Constants
    //

    uint16 public constant MAX_MINT = 9500;

    //
    // Errors
    //

    error InvalidSaleInterval(uint256 start, uint256 finish);
    error InvalidWhitelistRoot();

    error SaleNotFound(uint256 saleId);
    error ZeroMintQuantity();
    error NotInSalePhase(
        uint256 saleId,
        uint256 start,
        uint256 finish,
        uint256 current
    );
    error UserNotWhitelistedOrWrongProof(
        uint256 saleId,
        address user,
        bytes32[] proof
    );
    error WrongValueSentForMint(
        uint256 saleId,
        uint256 value,
        uint256 price,
        uint8 quantity
    );
    error MaximumSaleLimitReached(uint256 saleId, address user, uint8 limit);
    error MaximumSupplyReached();

    //
    // Events
    //

    event LogSetURI(string newURI);
    event LogSaleCreated(
        uint256 indexed saleId,
        uint64 start,
        uint64 finish,
        uint8 limit,
        uint64 price,
        bool whitelist,
        bytes32 root
    );
    event LogSaleEdited(
        uint256 indexed saleId,
        uint64 start,
        uint64 finish,
        uint8 limit,
        uint64 price,
        bool whitelist,
        bytes32 root
    );
    event LogSale(uint256 indexed saleId, address indexed to, uint256 quantity);

    //
    // Structs
    //

    /// Defines the parameters for a sale period.
    /// This is created by the contract's Sale Admin.
    /// A sale period has a start time, finish time, mint price, mint limit and a merkle root.
    /// The root parameter indicates the current sale's merkle root (0 for public sales).
    /// The whitelist boolean is 'true' for all whitelist mint periods and 'false' for public mints.
    /// A sale is active when block.timestamp in interval [start, finish].
    /// The price indicates how much a user has to pay for one NFT in this period.
    /// The limit specifies how many NFTs a user can mint during this period.
    struct Sale {
        bytes32 root;
        bool whitelist;
        uint64 start;
        uint64 finish;
        uint64 price;
        uint8 limit;
    }

    //
    // State
    //

    /// Base NFT metadata URI.
    string private _URI;

    /// Id of the next NFT id to mint (sequential id).
    uint256 public nextToMint = 1;

    /// List of sale phases.
    Sale[] private _sales;

    /// Mapping of the quantity of NFTs minted to each address.
    /// Used to track and cap how many tokens an address is allowed to mint per round.
    /// current sale id => user address => number of NFTs minted
    mapping(uint256 => mapping(address => uint256)) private _minted;

    //
    // ERC721
    //

    /// @dev See {IERC721Metadata-tokenURI}.
    function _baseURI() internal view override returns (string memory) {
        return _URI;
    }

    //
    // Constructor
    //

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        string memory _initialURI
    ) ONFT721(_name, _symbol, _lzEndpoint) {
        setURI(_initialURI);
    }

    //
    // Owner API
    //

    function setURI(string memory _newURI) public onlyOwner {
        _URI = _newURI;

        emit LogSetURI(_newURI);
    }

    /// @notice Adds a new sale period.
    /// @dev Can only be called by the contract owner.
    /// @param _start The start of the sale.
    /// @param _finish The end of the sale.
    /// @param _limit The maximum number of NFTs an account can mint during this period.
    /// @param _price The price of each NFT during this period.
    /// @param _whitelist Whether the sale is a whitelist sale
    /// @param _root When adding a whitelist sale, this parameter defines the merkle root to be used for verification.
    function addSale(
        uint64 _start,
        uint64 _finish,
        uint8 _limit,
        uint64 _price,
        bool _whitelist,
        bytes32 _root
    ) external onlyOwner {
        _validateSaleParams(_start, _finish, _whitelist, _root);

        Sale memory sale = Sale({
            start: _start,
            finish: _finish,
            limit: _limit,
            price: _price,
            whitelist: _whitelist,
            root: _root
        });
        _sales.push(sale);

        emit LogSaleCreated(
            _sales.length - 1,
            _start,
            _finish,
            _limit,
            _price,
            _whitelist,
            _root
        );
    }

    /// @notice Edits a Sale Phase
    /// @dev Can only be called by the contract owner.
    /// @param _saleId The unique ID of the sale to be edited
    /// @param _start The new start time we want the sale to have
    /// @param _finish The new end time we want the sale to have
    /// @param _limit The new limit of NFTs we want the sale to have
    /// @param _price The new price we want the NFTs to have
    /// @param _whitelist Whether it is a whitelist sale.
    /// @param _root Defines the root to be used for whitelist verification.
    /// If we want any Sale parameter to stay unchanged, send the same value as a parameter to the function
    function editSale(
        uint256 _saleId,
        uint64 _start,
        uint64 _finish,
        uint8 _limit,
        uint64 _price,
        bool _whitelist,
        bytes32 _root
    ) external onlyOwner {
        _validateSaleParams(_start, _finish, _whitelist, _root);
        if (_saleId >= _sales.length) revert SaleNotFound(_saleId);

        Sale storage sale = _sales[_saleId];
        sale.start = _start;
        sale.finish = _finish;
        sale.limit = _limit;
        sale.price = _price;
        sale.whitelist = _whitelist;
        sale.root = _root;

        emit LogSaleEdited(
            _saleId,
            _start,
            _finish,
            _limit,
            _price,
            _whitelist,
            _root
        );
    }

    /// @notice Withdraws any ETH sent to this contract.
    /// @dev Only callable by this contract's owner.
    /// @param _to The address to withdraw to.
    /// @param _amount The amount of ETH (in Wei) to withdraw.
    function withdrawEther(address _to, uint256 _amount) external onlyOwner {
        payable(_to).transfer(_amount);
    }

    /// Withdraws any ERC20 tokens sent to the contract.
    /// @dev only callable by the owner.
    /// @param _token The ERC20 token to withdraw
    /// @param _to The address to withdraw to.
    /// @param _amount The amount to withdraw
    function withdrawERC20(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    //
    // Public Read API
    //

    function getSale(uint256 _saleId) external view returns (Sale memory) {
        return _sales[_saleId];
    }

    function getSalesCount() external view returns (uint256) {
        return _sales.length;
    }

    function isSaleActive(uint256 _saleId) external view returns (bool) {
        Sale memory sale = _sales[_saleId];
        return block.timestamp >= sale.start && block.timestamp <= sale.finish;
    }

    function getMintedAmount(uint256 _saleId, address _user)
        external
        view
        returns (uint256)
    {
        return _minted[_saleId][_user];
    }

    //
    // Public Write API
    //

    function saleMint(
        uint256 _saleId,
        address _user,
        uint8 _quantity,
        bytes32[] calldata _proof
    ) external payable {
        // check if sale is registered and quantity is grater than zero
        if (_saleId >= _sales.length) revert SaleNotFound(_saleId);
        if (_quantity == 0) revert ZeroMintQuantity();

        Sale memory sale = _sales[_saleId];
        if (block.timestamp < sale.start || block.timestamp > sale.finish)
            revert NotInSalePhase(
                _saleId,
                sale.start,
                sale.finish,
                block.timestamp
            );

        // validate whitelist
        if (sale.whitelist) {
            bytes32 leaf = keccak256(abi.encodePacked(_user));
            if (!_verify(sale.root, _proof, leaf))
                revert UserNotWhitelistedOrWrongProof(_saleId, _user, _proof);
        }

        // validate ETH amount send to contract
        if (msg.value != _quantity * sale.price) {
            revert WrongValueSentForMint(
                _saleId,
                msg.value,
                sale.price,
                _quantity
            );
        }

        // validate individual mint limit
        uint256 availableUser = sale.limit - _minted[_saleId][_user];
        if (availableUser < _quantity) {
            revert MaximumSaleLimitReached(_saleId, _user, sale.limit);
        }

        // validate total mint limit
        uint256 mintedBefore = nextToMint;
        uint256 availableTotal = 1 + MAX_MINT - mintedBefore;
        if (availableTotal == 0) {
            revert MaximumSupplyReached();
        }

        // bound the quantity to mint and increase mint count
        uint256 quantityToMint = Math.min(availableTotal, _quantity);
        _minted[_saleId][_user] += quantityToMint;
        nextToMint += quantityToMint;

        // mint NFTs
        for (uint256 i = 0; i < quantityToMint; ) {
            _mint(_user, mintedBefore + i);
            unchecked {
                ++i;
            }
        }

        // emit sale event
        emit LogSale(_saleId, _user, quantityToMint);

        // refund leftover eth to buyer
        if (quantityToMint < _quantity) {
            // can fail when minting through a contract
            payable(msg.sender).transfer(
                sale.price * (_quantity - quantityToMint)
            );
        }
    }

    //
    // Internal
    //

    function _validateSaleParams(
        uint64 _start,
        uint64 _finish,
        bool _whitelist,
        bytes32 _root
    ) internal pure {
        if (_start > _finish) revert InvalidSaleInterval(_start, _finish);
        if (_whitelist && _root == bytes32(0)) revert InvalidWhitelistRoot();
    }

    /// @notice Internal merkle proof verification.
    /// @dev Verify that `proof` is valid and `leaf` occurs in the merkle tree with root hash `merkleRoot`.
    /// @param root The Merkle Tree Root to be used for verification
    /// @param proof The merkle proof.
    /// @param leaf The leaf node to find.
    function _verify(
        bytes32 root,
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bool verified) {
        verified = proof.verify(root, leaf);
    }
}