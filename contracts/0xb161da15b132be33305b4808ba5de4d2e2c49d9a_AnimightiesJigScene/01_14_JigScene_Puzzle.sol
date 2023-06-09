// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract AnimightiesJigScene is ERC1155, Ownable, AccessControl {
	using SafeMath for uint256;
	using Strings for uint256;

	bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
    uint256 public constant NUMBER_OF_LAYERS_PER_PUZZLE = 12;
    uint256 public constant MAX_PUZZLES_SUPPLY = 420;
    uint256 public constant PRICE = 0.05 ether;
    string private _base_uri;


    uint256[] public layers_ids = [
            500, 501,
            502, 503,
            504, 505,
            506, 507,
            508, 509,
            510, 511
        ];

    uint256[] private burning_amounts = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];

	uint256 public completedPuzzleCount = 0;
    uint256 public layersLeftToMint = NUMBER_OF_LAYERS_PER_PUZZLE * MAX_PUZZLES_SUPPLY;
    uint256 public reserved = 100;
    bool public paused_mint = true;
    address lolabs_splitter;
    mapping(uint256 => uint256) private _totalSupply;

	modifier whenMintNotPaused() {
        require(!paused_mint, "AnimightiesJigScene: mint is paused");
        _;
    }

	event MintPaused(address account);

    event MintUnpaused(address account);

	constructor(
		string memory uri_,
		address lolabs_splitter_,
		address white_listed
	)
		ERC1155(uri_)
	{
        _base_uri = uri_;
		lolabs_splitter = lolabs_splitter_;
		_setupRole(WHITE_LIST_ROLE, msg.sender);
        _setupRole(WHITE_LIST_ROLE, white_listed);
	}

	function mint(uint256 num) public payable whenMintNotPaused(){
		require( msg.value >= PRICE * num ,                          		"AnimightiesJigScene: Ether sent is less than PRICE*num" );
		require( num <= NUMBER_OF_LAYERS_PER_PUZZLE ,                       "AnimightiesJigScene: Trying to mint more than NUMBER_OF_LAYERS_PER_PUZZLE" );
		require( msg.sender == tx.origin ,                                  "AnimightiesJigScene: contracts cannot mint" );
		for(uint256 i = 0; i < num; i++) {
            _LFG(msg.sender);
        }
    }

	function airdrop(address[] calldata _addresses) external onlyRole(WHITE_LIST_ROLE) {
		for(uint256 i = 0; i < _addresses.length; i++) {
			_LFG(_addresses[i]);
        }
    }

    function giveaway(address account) external onlyRole(WHITE_LIST_ROLE) {
        require(reserved > 0, 	      	"AnimightiesJigScene: Exceeds maximum AnimightiesJigScene giveaway supply" );
        reserved -= 1;
        _LFG(account);
    }

    // remove before production
    function giveawayBatch(address account) external onlyRole(WHITE_LIST_ROLE) {
        layersLeftToMint -= 12;
		_mintBatch(account, layers_ids, burning_amounts, "");
    }

    function _LFG(address account) private {
		require( layersLeftToMint - reserved > 0, 	      	"AnimightiesJigScene: Exceeds maximum AnimightiesJigScene supply" );
		uint256 id = _generateRandomTokenId(account);
		layersLeftToMint -= 1;
		_mint(account, id, 1, "");
	}

	function _generateRandomTokenId(address account) private view returns (uint256) {
		uint256 seed =
			uint256(
				keccak256(
					abi.encodePacked(block.timestamp + block.difficulty + block.gaslimit + (layersLeftToMint*block.number) +
						((uint256(keccak256(abi.encodePacked(account)))) / (block.timestamp+layersLeftToMint))
				)
			));

		uint256 id_index = seed.mod(NUMBER_OF_LAYERS_PER_PUZZLE);
		for (uint256 i = 0; i < NUMBER_OF_LAYERS_PER_PUZZLE; i++) {
			id_index = (id_index+i).mod(NUMBER_OF_LAYERS_PER_PUZZLE);
			if (totalSupply(layers_ids[id_index]) < MAX_PUZZLES_SUPPLY) {
				return layers_ids[id_index];
			}
		}
		return layers_ids[id_index];
	}

    function burnLayersToCompletePuzzle() external {
        require(completedPuzzleCount < MAX_PUZZLES_SUPPLY, 	      	"AnimightiesJigScene: Exceeds maximum MAX_PUZZLES_SUPPLY" );
        require( hasAllPieces(msg.sender) ,                         "AnimightiesJigScene: sender does not have all pieces" );
		require( msg.sender == tx.origin ,                          "AnimightiesJigScene: contracts cannot complete the puzzle" );
		completedPuzzleCount += 1;
        _burnBatch(msg.sender, layers_ids, burning_amounts);
        _mint(msg.sender, completedPuzzleCount, 1, "");
    }

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }

	function pauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = true;
        emit MintPaused(msg.sender);
    }

    function unpauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = false;
        emit MintUnpaused(msg.sender);
    }

	function setBaseURI(string memory newURI) public onlyRole(WHITE_LIST_ROLE) {
		_base_uri = newURI;
	}

	function updateLolaSplitterAddress(address _lolabs_splitter) public onlyRole(WHITE_LIST_ROLE) {
        lolabs_splitter = _lolabs_splitter;
    }

	function getLolabsSplitter() public view onlyRole(WHITE_LIST_ROLE) returns(address splitter) {
        return lolabs_splitter;
    }

    function withdrawAllToSplitter() public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, 							 "AnimightiesJigScene: withdraw all call without balance");
        require(payable(lolabs_splitter).send(_balance), "AnimightiesJigScene: FAILED withdraw all call");
    }

	function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(exists(tokenId), "AnimightiesJigScene: URI query for nonexistent token");
        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
            : '';
	}

    function uri(uint256 tokenId) public view virtual override(ERC1155) returns (string memory) {
        return tokenURI(tokenId);
    }

	function getBaseURI() public view returns (string memory) {
		return _base_uri;
	}

    function hasAllPieces(address account) public view returns (bool) {
        address[] memory accounts = new address[](NUMBER_OF_LAYERS_PER_PUZZLE);

        for(uint256 i; i < NUMBER_OF_LAYERS_PER_PUZZLE; i++){
            accounts[i] = account;
        }

        uint256[] memory balances = balanceOfBatch(accounts, layers_ids);

        for(uint256 i; i < NUMBER_OF_LAYERS_PER_PUZZLE; i++){
            if(balances[i] < 1) {
                return false;
            }
        }

        return true;
    }

	function name() external pure returns (string memory) {
        return "AnimightiesJigScene";
    }

    function symbol() external pure returns (string memory) {
        return "AMJS";
    }

	function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}