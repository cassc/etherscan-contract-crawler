// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*****************************************************************************************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@.........................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@........................................................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@.........................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@..........................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@...................++++++++++++++++-......-+++++++++++++...[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@....................#@@@@@@@@@@@@@@@@%:....:%@@@@@@@@@@@@@*........*@@@@@@@@@@@@@%:....%%%.............+%#[email protected]@@@@@@@@@@@
@@@@@@@@@@@....................*@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@[email protected]@@[email protected]@%[email protected]@@@@@@@@@
@@@@@@@@@.....................*@@@@@@@@@@@@@@@@@@%:[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@%:[email protected]@@@@@@@@
@@@@@@@@.....................*@@@================:..-%@@#[email protected]@@@@@[email protected]@@@@%+=========#@@%[email protected]@@@[email protected]@%[email protected]@@@@@@@
@@@@@@@[email protected]@@[email protected]@@%[email protected]@@@@@=*@@@@@@+...........%@@[email protected]@@@[email protected]@@[email protected]@@@@@@
@@@@@@[email protected]@@:[email protected]@@%[email protected]@@@@@**@@@@@@+............%%[email protected]@@@[email protected]@@*[email protected]@@@@@
@@@@@[email protected]@@:[email protected]@@%[email protected]@@@@@**@@@@@%[email protected]@@@[email protected]@@*[email protected]@@@@
@@@@@[email protected]@@*[email protected]@@%[email protected]@@@@@**@@@@@#[email protected]@@@[email protected]@@[email protected]@@@@
@@@@[email protected]@@@%[email protected]@@%............#@@@@@**@@@@@[email protected]@@@#...%@@@*[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@:[email protected]@@%.............#@@@@**@@@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@%..............*@@@**@@@*[email protected]@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@%[email protected]@@**@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@:[email protected]@@@@@@@@@@@@@@@@@@#[email protected]@@%[email protected]@@**@@@[email protected]@@@@@@@@@@@@@@@@@@@@:[email protected]@@
@@@[email protected]@@@@@%[email protected]@@%[email protected]@@**@@@[email protected]@@@@@@...........#@@@[email protected]@@
@@@[email protected]@@@@@[email protected]@@%[email protected]@@**@@@[email protected]@@@@@@...........:@@@[email protected]@@
@@@[email protected]@@@@@[email protected]@@%[email protected]@@**@@@[email protected]@@@@@@...........:@@@*[email protected]@@
@@@[email protected]@@@@@[email protected]@@%[email protected]@@**@@@-..............:@@[email protected]@@@@@@...........:@@@*[email protected]@@
@@@[email protected]@@@@@-................#@@@-............=%@@#[email protected]@@*[email protected]@@[email protected]@@@@@@...........:@@@*[email protected]@@
@@@[email protected]@@@@@-................:#@@%############@@@#:[email protected]@@#############%@@#:[email protected]@@@@@@...........:@@@*[email protected]@
@@@[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@#:[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@-...........:@@@[email protected]@
@@@..........................%@@@@@-...................%@@@@@@@@@@@@@@#:[email protected]@@@@@@@@@@@@@@%....%@@@@%:...........:%@%[email protected]@
@@@...........................+%#+-....................:+%@@@@@@@@@@%+:[email protected]@@@@@@%@@@%+:....:+#@[email protected]@
@@@............................::........................:----------:............------:::--:........:[email protected]@
@@@..................................................................................[email protected]@
@@@..................................................................................[email protected]@
@@@..................................................................................[email protected]@
@@@.............................#%%%%%%%%%%=...%%%%%%%%%%%%%%%%%=...*%%%%%%%%%%-....:%%%%%%%%%%%+.........:%%%%%%%%%%%%%%[email protected]@@
@@@............................#@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@:[email protected]@@@@@@@@@@@@+.......:@@@@@@@@@@@@@@@[email protected]@@
@@@...........................*@@@@@@@@@@@@@@-.*#@@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@*[email protected]@@
@@@..........................#@@===========%@%-.:[email protected]@@@=====-.*@@[email protected]@@@@[email protected]@@=========*@@*...-%@@@@[email protected]@@
@@@[email protected]@[email protected]@@@[email protected]@*[email protected]@@@@:@@@:[email protected]@%[email protected]@@@@[email protected]@@
@@@@[email protected]@[email protected]@@-......*@@*.........:@@@@@:@@@:[email protected]@%[email protected]@@@@[email protected]@@@
@@@@[email protected]@#[email protected]@@*......*@@*.........:@@@@@:@@@:[email protected]@%[email protected]@@@@[email protected]@@@
@@@@[email protected]@@%[email protected]@@@%.....*@@*..........*@@@@:@@@%*......#%@@%[email protected]@@@@%#********[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@@@=....*@@*...........#@@@:@@@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@:[email protected]@@@@#....*@@*[email protected]@@:@@@@@@@@@@@@@@@%:[email protected]@@@@@@@@@@@@@@@@[email protected]@@@
@@@@@[email protected]@@@@%:[email protected]@@@@#....*@@*[email protected]@@:@@@@@@@[email protected]@%:[email protected]@@%[email protected]@@@@
@@@@@...................................:@@@@@@[email protected]@@@@#....*@@*[email protected]@@:@@@@@*:.......:@@@[email protected]@@:[email protected]@@@@
@@@@@@@[email protected]@@@@[email protected]@@@@#....*@@*[email protected]@@:@@@@@[email protected]@[email protected]@@[email protected]@@@@@@
@@@@@@@......................==:[email protected]@@@@[email protected]@@@@#....*@@*[email protected]@@:@@@@@[email protected]@[email protected]@@[email protected]@@@@@@
@@@@@@@@[email protected]@%:........%@@@@[email protected]@@@@#....:@@%:[email protected]@*[email protected]@@@@[email protected]@[email protected]@@[email protected]@@@@@@@
@@@@@@@@@....................:@@@@@@@@@@@@@@@*[email protected]@@@@#[email protected]@@@@@@@@@@@@@@#[email protected]@@@@[email protected]@..*@@@@@@@@@@@@@@@[email protected]@@@@@@@@
@@@@@@@@@@@[email protected]@@@@@@@@@@@@*.........#@@@@#......:%@@@@@@@@@@@@#[email protected]@@@@[email protected]@...*@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@
@@@@@@@@@@@@[email protected]@@@@@@@@@@*...........*@@@=.......-%@@@@@@@@@@*....*@@@@-.........:#*....*@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@
@@@@@@@@@@@@@@..................-----------.............---.........:----------......---:...........:[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@@@@.........................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@.........................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@.........................................................[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@........................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@.......................................................[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*****************************************************************************************************************************************************/

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";

contract FockStore is ERC1155, Ownable, ReentrancyGuard, ERC2981 {
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    struct Utility {
        uint256 utilityId;
        string name;
        uint256 totalSupply;
        uint256 maxSupply;
        address contractAddress;
    } 

    // Events
    event TokenMinted(address owner, uint256 utilityId, uint256 quantity);
    event TokenClaimed(address owner, uint256 utilityId);

    mapping(bytes => bool) public signatureUsed;

    mapping(uint256 => Utility) public utilities;

    // Define the signer wallet
    address private signer;

    // Define if market is active
    bool public marketIsActive = true;

    // Define if Claim is active
    bool public claimIsActive = true;

    // Base URI
    string private baseURI;

    uint256 public maxUtilityId = 0;

    string public name;
    string public symbol;
    string public baseExtension = ".json";

    /**
	 * Validate if an address is a contract
	 */
	function isContract(address _addr) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_addr)
		}
		return size > 0;
	}

    /**
     * Contract constructor
     */
    constructor(string memory _name, string memory _symbol, address _signer, string memory _baseURI) ERC1155(_baseURI) {
        name = _name;
        symbol = _symbol;
        signer = _signer;
        setBaseURI(_baseURI);

        _setDefaultRoyalty(msg.sender, 500);
    }

    /*
     * Set the signer wallet
     */
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /*
     * Pause market if active, make active if paused
     */
    function setMarketState(bool _newState) public onlyOwner {
        marketIsActive = _newState;
    }

    /*
     * Pause claim if active, make active if paused
     */
    function setClaimState(bool _newState) public onlyOwner {
        claimIsActive = _newState;
    }

    /**
     * Set Max supply for an utility
     */
    function setUtility(uint256 _utilityId, string memory _name, uint256 _maxSupply, address _contractAddress) public onlyOwner {
        maxUtilityId = maxUtilityId.add(1);
        utilities[_utilityId].utilityId = _utilityId;
        utilities[_utilityId].name = _name;
        utilities[_utilityId].maxSupply = _maxSupply;
        utilities[_utilityId].contractAddress = _contractAddress;
    }

    /**
     * Set Max supply for an utility
     */
    function setMaxSupply(uint256 _utilityId, uint256 _max) public onlyOwner {
        utilities[_utilityId].maxSupply = _max;
    }

    /**
     * Set Contract Address for an utility
     */
    function setUtilityContract(uint256 _utilityId, address _contractAddress) public onlyOwner {
        utilities[_utilityId].contractAddress = _contractAddress;
    }

    /**
     * Set the utility name
     */
    function setUtilityName(uint256 _utilityId, string memory _name) public onlyOwner {
        utilities[_utilityId].name = _name;
    }

    /**
     * Set max utilityId available
     */
    function setMaxUtilityId(uint256 _newUtilityId) public onlyOwner {
        maxUtilityId = _newUtilityId;
    }

    /**
     * Get utility supply
     */
    function getUtility(uint256 _utilityId) public view returns (Utility memory) {
        require(isValidUtility(_utilityId), 'Invalid utility id');

        return utilities[_utilityId];
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory _baseURI) onlyOwner public {
        baseURI = _baseURI;
    }

    /**
     * Uri for utilities
     */
    function uri(uint256 _utilityId) public view override returns (string memory)
    {
        require(isValidUtility(_utilityId), "URI requested for invalid token");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _utilityId.toString(), baseExtension))
                : baseURI;
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Set Royalty
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * Supports Interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC1155, ERC2981)
        returns (bool)
    {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Is valid a utility
     */
    function isValidUtility(uint256 _utilityId) public view returns(bool) {
        return (_utilityId > 0 && _utilityId <= maxUtilityId);
    }

    /**
     * Is valid sign
     */
    function isValidSign(
            address _wallet,
            uint _utilityId, 
            uint _qty, 
            string memory _nonce,
            bytes memory _signature
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(_wallet, _utilityId, _qty, _nonce));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address receivedAddress = ECDSA.recover(message, _signature);

        return receivedAddress != address(0) && receivedAddress == signer;
    }

    /**
     * Mint utilities
     */
    function mint(uint _utilityId, uint _qty, string memory _nonce, bytes memory _signature) external nonReentrant {
        require(marketIsActive, "Mint is not available right now");
        require(isValidUtility(_utilityId) && utilities[_utilityId].maxSupply > 0, "utilityId is not valid");
        require(!signatureUsed[_signature], "Signature has already been used");
        require(utilities[_utilityId].totalSupply.add(_qty) <= utilities[_utilityId].maxSupply, "Qty tokens would exceed max supply");

        address destAddress = msg.sender;

        // Caller is an external contract
        if (utilities[_utilityId].contractAddress != address(0)) {
            require(isContract(msg.sender) && utilities[_utilityId].contractAddress == msg.sender, 'Sender is not a contract.');
            // tx.origin is the user's wallet
            destAddress = tx.origin;
        }

        require(isValidSign(destAddress, _utilityId, _qty, _nonce, _signature), "Signature is not valid");

        signatureUsed[_signature] = true;
        utilities[_utilityId].totalSupply = utilities[_utilityId].totalSupply.add(_qty);
        _mint(destAddress, _utilityId, _qty, '');

        emit TokenMinted(destAddress, _utilityId, _qty);
    }

    /**
    * Claim utility
    */
    function claim(uint _utilityId) external nonReentrant {
        require(claimIsActive, 'Claim is not active right now');
        require(balanceOf(msg.sender, _utilityId) > 0, "Balance must be greater than Zero");
        
        super._burn(msg.sender, _utilityId, 1);

		emit TokenClaimed(msg.sender, _utilityId);
    }
}