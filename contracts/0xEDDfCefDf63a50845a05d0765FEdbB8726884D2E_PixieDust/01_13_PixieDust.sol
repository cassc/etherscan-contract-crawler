// SPDX-License-Identifier: MIT


/*
･ *ﾟ
　 ･ ﾟ*
     ･｡     
   *･｡
      *.｡ 
           ｡･
              °*.
              ｡･  
               ｡･
                ｡｡ 
                  ･ ﾟ*.
                      ﾟ*.
                 ｡｡ ･
             ｡ ･ﾟ
       ｡°*.
   ｡*･｡
*/

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract PixieJars {
    function walletOfOwner(address) external virtual view returns (uint256[] memory);
    function ownerOf(uint256) external virtual view returns (address);
    function balanceOf(address) external virtual view returns (uint256);
}

abstract contract CompanionJars {
    function stakedBy(uint256) external virtual view returns (address);
    function balanceOf(address) external virtual view returns (uint256);
}

abstract contract WalletOfOwnerHelper {
    function walletOfOwner(address collectionAddress, address owner, uint256 startTokenID, uint256 endTokenID) public virtual view returns (uint256[] memory);
}

contract PixieDust is ERC1155, ERC20, Ownable {

    uint256 public constant JAR_OF_DUST_ID = 1;
    uint256 public constant JAR_OF_DUST_VALUE = 100 * 10**18;
    uint256 public constant INITIAL_CLAIM_PER_PIXIE = 50 * 10**18;

    string public dustTokenURI;
    string internal _contractURI = "";
    uint256[20] public claimedDust;
    mapping(address => bool) public allowedOperator;
    PixieJars pixieJars;
    CompanionJars companionJars;
    WalletOfOwnerHelper walletOfOwnerHelper;

    constructor(string memory mContractURI, string memory _dustURI, address _pixieJars, address _walletOfOwnerHelper) ERC1155("") ERC20("Pixie Dust", "PD") {
        pixieJars = PixieJars(_pixieJars);
        walletOfOwnerHelper = WalletOfOwnerHelper(_walletOfOwnerHelper);
        dustTokenURI = _dustURI;
        _contractURI = mContractURI;
        emit URI(dustTokenURI, JAR_OF_DUST_ID);
    }

    function setPixieJarsContract(address _pixieJars) external onlyOwner {
        pixieJars = PixieJars(_pixieJars);
    }

    function setCompanionJarsContract(address _companionJars) external onlyOwner {
        companionJars = CompanionJars(_companionJars);
    }

    function setWalletOfOwnerHelper(address _walletOfOwnerHelper) external onlyOwner {
        walletOfOwnerHelper = WalletOfOwnerHelper(_walletOfOwnerHelper);
    }

    function setDustTokenURI(string memory _dustURI) external onlyOwner {
        dustTokenURI = _dustURI;
        emit URI(dustTokenURI, JAR_OF_DUST_ID);
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function setAllowed(address _operator, bool _allowed) external onlyOwner {
        allowedOperator[_operator] = _allowed;
    }

    function mintDust(address to, uint256 amount) external {
        require(allowedOperator[msg.sender], "NOT ALLOWED");
        _mint(to, amount);
    }

    function burnDust(address from, uint256 amount) external {
        require(allowedOperator[msg.sender], "NOT ALLOWED");
        _burn(from, amount);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(id == JAR_OF_DUST_ID);
        return dustTokenURI;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(id == JAR_OF_DUST_ID, "INVALID TOKEN");
        uint256 dustBalance = balanceOf(account);
        return dustBalance / JAR_OF_DUST_VALUE;
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory) public view virtual override returns (uint256[] memory) {
        uint256[] memory batchBalances = new uint256[](accounts.length);
        uint256 dustBalance;
        for(uint256 i = 0;i < accounts.length;i++) {
            dustBalance = balanceOf(accounts[i]);
            batchBalances[i] = dustBalance / JAR_OF_DUST_VALUE;
        }
        return batchBalances;
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) internal virtual override {
        require(id == JAR_OF_DUST_ID);

        uint256 dustAmount = amount * JAR_OF_DUST_VALUE;
        _transfer(from, to, dustAmount);
    }

    function _safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) internal virtual override {
        revert("NO BATCH TRANSFERS");
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fromDustAfter = balanceOf(from);
        uint256 toDustAfter = balanceOf(to);
        uint256 fromJarsAfter = fromDustAfter / JAR_OF_DUST_VALUE;
        uint256 toJarsAfter = toDustAfter / JAR_OF_DUST_VALUE;
        uint256 fromJarsBefore = (fromDustAfter + amount) / JAR_OF_DUST_VALUE;
        uint256 toJarsBefore = 0;
        if(toDustAfter >= amount) {
            toJarsBefore = (toDustAfter - amount) / JAR_OF_DUST_VALUE;
        }
        uint256 toJarDiff = toJarsAfter - toJarsBefore;
        uint256 fromJarDiff = fromJarsBefore - fromJarsAfter;
        if(toJarDiff == fromJarDiff) {
            if(toJarDiff > 0) {
                emit TransferSingle(_msgSender(), from, to, JAR_OF_DUST_ID, toJarDiff);
            }
        } else if(toJarDiff > fromJarDiff) {
            if(fromJarDiff > 0) {
                emit TransferSingle(_msgSender(), from, to, JAR_OF_DUST_ID, fromJarDiff);
            }
            emit TransferSingle(_msgSender(), address(0), to, JAR_OF_DUST_ID, (toJarDiff - fromJarDiff));
        } else {
            if(toJarDiff > 0) {
                emit TransferSingle(_msgSender(), from, to, JAR_OF_DUST_ID, toJarDiff);
            }
            emit TransferSingle(_msgSender(), from, address(0), JAR_OF_DUST_ID, (fromJarDiff - toJarDiff));
        }
    }

    function claimDust(uint256[] calldata pixieTokenId) external {
        require(pixieTokenId.length > 0);
        uint256[] memory claimUpdates = new uint256[](20);
        uint256 totalClaim = 0;
        uint256 a = 0;
        uint256 b = 0;
        for(uint256 i = 0;i < pixieTokenId.length;i++) {
            if(pixieJars.ownerOf(pixieTokenId[i]) == msg.sender || companionJars.stakedBy(pixieTokenId[i]) == msg.sender) {
                a = pixieTokenId[i] / 256;
                b = pixieTokenId[i] % 256;
                if(claimedDust[a] &  2**b == 0 && claimUpdates[a] &  2**b == 0) {
                    totalClaim = totalClaim + INITIAL_CLAIM_PER_PIXIE;
                    claimUpdates[a] = claimUpdates[a] + 2 ** b;
                }
            }
        }
        require(totalClaim > 0);
        for(uint256 i = 0;i < claimUpdates.length;i++) {
            if(claimUpdates[i] > 0) {
                claimedDust[i] = claimedDust[i] | claimUpdates[i];
            }
        }
        _mint(msg.sender, totalClaim);
    }

    function isClaimed(uint256 pixieTokenId) external view returns(bool) {
        uint256 a = pixieTokenId / 256;
        uint256 b = pixieTokenId % 256;
        return claimedDust[a] & 2**b != 0;
    }

    function unclaimedPixiesByOwner(address _owner) external view returns(uint256[] memory) {
        uint256 pixieBalance = pixieJars.balanceOf(_owner);
        uint256 combinedBalance = companionJars.balanceOf(_owner);
        if(pixieBalance == 0 && combinedBalance == 0) { revert("No pixies owned."); }
        uint256[] memory pixieTokenIds = new uint256[](pixieBalance);
        pixieTokenIds = pixieJars.walletOfOwner(_owner);
        uint256 unclaimedCount = 0;
        for(uint256 i = 0;i < pixieTokenIds.length;i++) {
            if(!this.isClaimed(pixieTokenIds[i])) {
                unclaimedCount++;
            }
        }
        uint256[] memory combinedTokenIds = new uint256[](combinedBalance);
        combinedTokenIds = walletOfOwnerHelper.walletOfOwner(address(companionJars), _owner, 1, 5000);
        for(uint256 i = 0;i < combinedTokenIds.length;i++) {
            if(!this.isClaimed(combinedTokenIds[i])) {
                unclaimedCount++;
            }
        }
        if(unclaimedCount == 0) { revert("No unclaimed dust."); }
        uint256[] memory unclaimedTokenIds = new uint256[](unclaimedCount);
        uint256 unclaimedIndex = 0;
        for(uint256 i = 0;i < pixieTokenIds.length;i++) {
            if(!this.isClaimed(pixieTokenIds[i])) {
                unclaimedTokenIds[unclaimedIndex] = pixieTokenIds[i];
                unclaimedIndex++;
                if(unclaimedIndex == unclaimedCount) break;
            }
        }
        for(uint256 i = 0;i < combinedTokenIds.length;i++) {
            if(!this.isClaimed(combinedTokenIds[i])) {
                unclaimedTokenIds[unclaimedIndex] = combinedTokenIds[i];
                unclaimedIndex++;
                if(unclaimedIndex == unclaimedCount) break;
            }
        }

        return unclaimedTokenIds;
    }
}