//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LendingPool is Ownable, ERC721 {
    using Address for address payable;

    struct Loan {
        uint nft;
        uint startTime;
        uint startInterestSum;
        uint borrowed;
    }

    IERC721 public constant nftContract =
        IERC721(0xCa7cA7BcC765F77339bE2d648BA53ce9c8a262bD);
    uint256 public constant maxLoanLength = 2 weeks;
    uint256 public constant maxInterestPerEthPerSecond = 25367833587; // ~ 0.8 ether / 1 years;
    uint256 public maxPrice;
    bool public newBorrowsAllowed = true;
    address public oracle;
    uint public sumInterestPerEth = 0;
    uint public lastUpdate;
    uint public totalBorrowed = 0;
    Loan[] public loans;
    string private baseURI = "https://api.tubbysea.com/nft/ethereum/";

    constructor(address _oracle, uint _maxPrice) ERC721("TubbyLoan", "TL") {
        oracle = _oracle;
        maxPrice = _maxPrice;
        lastUpdate = block.timestamp;
    }

    // amountInThisTx -> msg.value if payable method, 0 otherwise
    modifier updateInterest(uint amountInThisTx) {
        uint elapsed = block.timestamp - lastUpdate;
        // this can't overflow
        // if we assume elapsed = 10 years = 10*365*24*3600 = 315360000
        // and totalBorrowed = 1M eth = 1e6*1e18 = 1e24
        // then that's only 142.52 bits, way lower than the 256 bits required for it to overflow.
        // There's one attack where you could blow up totalBorrowed by cycling borrows,
        // but since this requires a tubby each time it can only be done 20k times, which only increase bits by 14.28 -> still safu
        sumInterestPerEth += (elapsed * totalBorrowed * maxInterestPerEthPerSecond) / (address(this).balance - amountInThisTx + totalBorrowed + 1); // +1 prevents divisions by 0
        lastUpdate = block.timestamp;
        _;
    }

    function _borrow(
        uint nftId,
        uint256 price) internal {
        require(nftContract.ownerOf(nftId) == msg.sender, "not owner");
        loans.push(Loan(nftId, block.timestamp, sumInterestPerEth, price));
        nftContract.transferFrom(msg.sender, address(this), nftId);
        _mint(msg.sender, loans.length-1);
    }

    function borrow(
        uint[] calldata nftId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) external updateInterest(0) {
        require(newBorrowsAllowed, "paused");
        checkOracle(price, deadline, v, r, s);
        uint length = nftId.length;
        totalBorrowed += price * length;
        for(uint i=0; i<length; i++){
            _borrow(nftId[i], price);
        }
        payable(msg.sender).sendValue(price * length);
    }

    function repay(uint loanId) external payable updateInterest(msg.value) {
        require(ownerOf(loanId) == msg.sender, "not owner");
        Loan storage loan = loans[loanId];
        require((block.timestamp - loan.startTime) < maxLoanLength, "expired");
        uint interest = ((sumInterestPerEth - loan.startInterestSum) * loan.borrowed) / 1e18;
        _burn(loanId);
        totalBorrowed -= loan.borrowed;
        payable(msg.sender).sendValue(msg.value - (interest + loan.borrowed)); // overflow checks implictly check that amount is enough
        nftContract.transferFrom(address(this), msg.sender, loan.nft);
    }

    function claw(uint loanId) external onlyOwner updateInterest(0) {
        Loan storage loan = loans[loanId];
        require(_exists(loanId), "loan closed");
        require(block.timestamp > (loan.startTime + maxLoanLength), "not expired");
        _burn(loanId);
        totalBorrowed -= loan.borrowed;
        nftContract.transferFrom(address(this), msg.sender, loan.nft);
    }

    function setNewBorrowsAllowed(bool newValue) external onlyOwner {
        newBorrowsAllowed = newValue;
    }

    function setOracle(address newValue) external onlyOwner {
        oracle = newValue;
    }

    function deposit() external payable onlyOwner updateInterest(msg.value) {}

    function withdraw(uint amount) external onlyOwner updateInterest(0) {
        payable(msg.sender).sendValue(amount);
    }

    function checkOracle(
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view {
        require(block.timestamp < deadline, "deadline over");
        require(
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n84",
                        price,
                        deadline,
                        address(nftContract)
                    )
                ),
                v,
                r,
                s
            ) == oracle,
            "not oracle"
        );
        require(price < maxPrice, "max price");
    }

    function currentSumInterestPerEth() view public returns (uint) {
        uint elapsed = block.timestamp - lastUpdate;
        return sumInterestPerEth + (elapsed * totalBorrowed * maxInterestPerEthPerSecond) / (address(this).balance + totalBorrowed + 1);
    }

    function infoToRepayLoan(uint loanId) view external returns (uint deadline, uint totalRepay){
        deadline = block.timestamp + maxLoanLength;
        Loan storage loan = loans[loanId];
        uint interest = ((currentSumInterestPerEth() - loan.startInterestSum) * loan.borrowed) / 1e18;
        totalRepay = interest + loan.borrowed;
    }

    function currentAnnualInterest(uint priceOfNextItem) external view returns (uint interest) {
        uint borrowed = priceOfNextItem + totalBorrowed;
        return (365 days * borrowed * maxInterestPerEthPerSecond) / (address(this).balance + totalBorrowed + 1);
    }

    function totalSupply() external view returns (uint supply){
        return loans.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toHexString(uint160(address(nftContract)), 20), "/"));
    }

    function setMaxPrice(uint newMaxPrice) external onlyOwner {
        maxPrice = newMaxPrice;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    fallback() external {
        // money can still be received through self-destruct, which makes it possible to change balance without calling updateInterested, but if
        // owner does that -> they are lowering the money they earn through interest
        // debtor does that -> they always lose money because all loans are < 2 weeks
        revert();
    }
}