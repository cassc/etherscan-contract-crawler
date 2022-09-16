// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface ICM {
    function balanceOf(address owner) external view returns (uint256); 
}
interface IV3 {
    function balanceOf(address owner) external view returns (uint256);
}
contract v69Phunks is ERC721r, Ownable {
    mapping(address => bool) public isAList;
    mapping(address => uint256) public walletMinted;
    uint16 maxPhree = 1369;
    uint16 public maxWifeys = 6969; 
    uint64 public mintPrice = 0.0069 ether;
    uint256 public mintedWifeys;
    uint256 MintedPhreeWifeys;
    bool public aListMintOn;
    bool public publicMintOn;
    bool mintSuccess;
    address public CMaddy = 0xe9b91d537c3Aa5A3fA87275FBD2e4feAAED69Bd0;
    address public v3addy  = 0xb7D405BEE01C70A9577316C1B9C2505F146e8842;
    string _baseTokenURI =
    "ipfs://QmXZ1MwSTi5BDX3t7G1UYzbYSHKCiwDxUPcoLzvE2Vdkke/";
    string public uriSuffix = ".json";

    constructor() ERC721r("v69 Phunks", "Wifeys", 6_969) {}
        modifier whenMintActive() {
            require(aListMintOn || publicMintOn, "Mint is not active");
            _;
        }
        function toggleAListMint() public onlyOwner {
            aListMintOn = !aListMintOn;
        } 
        //end alist mint and start publicmint
        function togglePublicMint() public onlyOwner{
            aListMintOn = false;
            publicMintOn = !publicMintOn;
        }
        function checkAList() public view returns(bool) {
            return isAList[msg.sender];
        }
        function aListSelf() public {
            ICM marc = ICM(CMaddy);
            IV3 v3 = IV3(v3addy);
            require(v3.balanceOf(msg.sender) > 0 || marc.balanceOf(msg.sender) > 0);
            isAList[msg.sender] = true;
        }
        function aListByOwner(address alist) public onlyOwner {
            isAList[alist] = true;
        }
    //mint wifey function for allowlist and public sale
    function mintWifeys(uint256 amount) public payable whenMintActive {
        require(amount > 0 && amount <= 69, "Invalid token count");
        require(mintedWifeys + amount < maxWifeys, "More than available supply");
        if (publicMintOn) {
            require(msg.value >= amount * mintPrice, "Incorrect amount of ether sent");
            _mintRandom(msg.sender, amount);
            mintSuccess = true;
            walletMinted[msg.sender] += amount;
            mintedWifeys += amount;
            } else if (aListMintOn) {
                if ((MintedPhreeWifeys < maxPhree && walletMinted[msg.sender] <1)) {
                    uint8 Phree = 0.0 ether;
                    require(amount == 1, "First one's on the house! Please mint one for free");
                    require(amount * Phree == msg.value, "First one's on the house! Please mint one for free");
                    ICM marc = ICM(CMaddy);
                    IV3 v3 = IV3(v3addy);
                    require(v3.balanceOf(msg.sender) > 0 || marc.balanceOf(msg.sender) > 0 || isAList[msg.sender] == true, "Plese wait for public mint");
                    MintedPhreeWifeys += amount;
                } else {
                    require(msg.value >= amount * mintPrice, "Incorrect amount of eth sent, please send 0.0069 eth per wifey");
                    ICM marc = ICM(CMaddy);
                    IV3 v3 = IV3(v3addy);
                    require(v3.balanceOf(msg.sender) > 0 || marc.balanceOf(msg.sender) > 0 || isAList[msg.sender] == true, "Please wait for public mint");
                } 
                _mintRandom(msg.sender, amount);
                mintSuccess = true;
                walletMinted[msg.sender] += amount;
                mintedWifeys += amount;
            } else {
                mintSuccess = false;
                require(mintSuccess, "Mint failed!");
            }
    }
        //metadata URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    //withdraw to contract deployer
    function withdraw() external onlyOwner {
            (bool success,) = msg.sender.call{value : address(this).balance}("");
            require(success, "Withdrawal failed");
        }
}