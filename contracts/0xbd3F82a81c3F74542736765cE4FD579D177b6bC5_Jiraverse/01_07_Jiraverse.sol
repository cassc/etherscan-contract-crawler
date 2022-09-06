// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Jiraverse is ERC721A, Ownable {
    using Strings for uint256;

    bool public private_sale_running;
    bool public refund_started;

    uint public public_sale_start_time = 2**255;

    mapping(uint => bytes32) public gen1_merkle_roots;
    mapping(uint => bytes32) public gen2_merkle_roots;

    mapping(address => uint) public gen1_claimed;
    mapping(address => uint) public gen2_claimed;

    string public base_uri = "https://jiraverseapi.xyz/api/wl/Meta/";

    address public constant JIRA_TOKEN_ADDRESS = 0x517AB044bda9629E785657DbbCae95C40C8f452C; // MAINNET
    // address public constant JIRA_TOKEN_ADDRESS = 0xb9E87970fD098aF6ca0361C3356435dB31e7Cdb5; // RINKEBY

    uint256 constant JIRA_PRICE = 200 ether;

    uint256 constant time_until_decrease = 15 minutes;
    uint256 constant decrease_amount = 0.025 ether;
    uint256 constant max_price = 0.55 ether;
    uint256 constant min_price = 0;
    uint256 constant time_to_start_decreasing = 30 minutes;

    uint256 public refund_price = 0.55 ether;
    mapping(address => uint) public total_paid;

    constructor () ERC721A("Jiraverse", "PGJ") { }
    
    function getCurrentMintingPrice() view public returns(uint256) {
        if (block.timestamp - public_sale_start_time <= time_to_start_decreasing) {
            return max_price;
        }

        uint decrease_start_time = public_sale_start_time + time_to_start_decreasing;
        
        if (((block.timestamp - decrease_start_time) / time_until_decrease) * decrease_amount >= max_price) {
            return min_price;
        }
        
        return max_price - (((block.timestamp - decrease_start_time) / time_until_decrease) * decrease_amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(base_uri, tokenId.toString()));
    }   

    function changeUri(string memory _new_uri) external onlyOwner {
        base_uri = _new_uri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function isGen1Whitelisted(address _user, bytes32 [] calldata _merkleProof, uint _allocation) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verifyCalldata(_merkleProof, gen1_merkle_roots[_allocation], leaf);
    }

    function isGen2Whitelisted(address _user, bytes32 [] calldata _merkleProof, uint _allocation) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verifyCalldata(_merkleProof, gen2_merkle_roots[_allocation], leaf);
    }
    
    function gen1Mint(uint _quantity, bytes32 [] calldata _gen1_merkle_proof, uint _gen1_allocation) external {
        require(tx.origin == msg.sender);
        require(private_sale_running, "Private sale is not running");
        require(_totalMinted() + _quantity * 2 < 10001, "Not enough tokens left to mint");

        require(isGen1Whitelisted(msg.sender, _gen1_merkle_proof, _gen1_allocation), "Invalid proof");

        uint num_claimed = gen1_claimed[msg.sender];
        require(num_claimed + _quantity <= _gen1_allocation, "You cannot claim that many tokens");

        IERC20(JIRA_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), JIRA_PRICE * _quantity);
        gen1_claimed[msg.sender] += _quantity;
        _mint(msg.sender, _quantity * 2);
    }

    function gen2Mint(uint _quantity, bytes32 [] calldata _gen2_merkle_proof, uint _gen2_allocation) external {
        require(tx.origin == msg.sender);
        require(private_sale_running, "Private sale is not running");
        require(_totalMinted() + _quantity < 10001, "Not enough tokens left to mint");

        require(isGen2Whitelisted(msg.sender, _gen2_merkle_proof, _gen2_allocation), "Invalid proof");

        uint num_claimed = gen2_claimed[msg.sender];
        require(num_claimed + _quantity <= _gen2_allocation, "You cannot claim that many tokens");

        IERC20(JIRA_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), JIRA_PRICE * _quantity);
        gen2_claimed[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function publicMint(uint _quantity) external payable {
        require(tx.origin == msg.sender);
        require(public_sale_start_time < block.timestamp, "Public sale is not running");
        require(_totalMinted() + _quantity < 6002, "Not enough tokens left to mint");

        require(msg.value >= _quantity * getCurrentMintingPrice(), "Incorrect ETH sent to mint");
        require(_getAux(msg.sender) + uint64(_quantity) < 4, "Cannot mint more than 3 during public");

        total_paid[msg.sender] += msg.value;
        _setAux(msg.sender, _getAux(msg.sender) + uint64(_quantity));
        _mint(msg.sender, _quantity);

        if (_totalMinted() == 6001) {
            refund_price = getCurrentMintingPrice();
        }
    }

    function claimRefund() external {
        require(total_paid[msg.sender] >= uint256(_getAux(msg.sender)) * refund_price, "Already claimed or did not mint");
        require(refund_started, "Refund period is not active yet");

        uint amount_owed = total_paid[msg.sender] - uint256(_getAux(msg.sender)) * refund_price;
        total_paid[msg.sender] = 0;
        payable(msg.sender).transfer(amount_owed);
    }

    function burn(uint _token_id) external {
        _burn(_token_id, true);
    }

    function updateGen1MerkleRoot(uint _allocation, bytes32 _new_root) external onlyOwner {
        gen1_merkle_roots[_allocation] = _new_root;
    }

    function updateGen2MerkleRoot(uint _allocation, bytes32 _new_root) external onlyOwner {
        gen2_merkle_roots[_allocation] = _new_root;
    }

    function togglePrivateSale() external onlyOwner {
        private_sale_running = !private_sale_running;
    }

    function enablePublicSale() external onlyOwner {
        public_sale_start_time = block.timestamp;
    }

    function disablePublicSale() external onlyOwner {
        public_sale_start_time = 2**255 - 1;
    }

    function toggleRefund() external onlyOwner {
        refund_started = !refund_started;
    }

    function adminMint(address _destination, uint _quantity) external onlyOwner {
        require(_totalMinted() + _quantity < 10001, "Not enough tokens left to mint");
        _mint(_destination, _quantity);
    }
    
    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function withdrawJIRA(address _to, uint _quantity) external onlyOwner {
        IERC20(JIRA_TOKEN_ADDRESS).transfer(_to, _quantity);
    }

    function deposit() external payable {}
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}