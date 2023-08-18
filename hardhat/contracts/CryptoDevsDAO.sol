// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {

    function getPrice() external view returns(uint256);

    function available(uint256 _tokenID) external view returns(bool);
    function purchase(uint256 _tokenID)external payable;

    }
interface ICryptoDevsNFT {
    //balanceOf returns the number of nft owned by the given address.
    function balanceOf(address owner) external view returns(uint256);

    //tokenOfOwnerbyIndex returns tokenId at given index for owner
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
    
}    
    
contract CryptoDevsDAO is Ownable {
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
}

    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes; //yes for this proposal 
        uint256 nayVotes;// no for this proposal
        bool executed;
        // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint=>bool) voters;
    }

    mapping(uint256=> Proposal) public proposals;
    //number of proposals that have been created.
    uint256 public numProposals;

    modifier nftHolderOnly {
        require(cryptoDevsNFT.balanceOf(msg.sender)>0,"NOT a DAO Member");
        _;
    }

    

    // _nftTokenId is the tokenId of nft that will be purchase from fakeNFT marketplace 
    function createProposal(uint _nftTokenId) external nftHolderOnly returns(uint256){
        //check wether nft is available or not
        require(nftMarketplace.available(_nftTokenId),"NFT NOT FOR SALE");
        // proposal is like an object of Proposal ,which we have assign the Proposal number ,so proposal will point to the Proposal struct of proposal number
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId=_nftTokenId;

        //set the proposal voting deadline to be (current time + 5minutes)
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;

    }

    modifier activeProposalOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline > block.timestamp,"Deadline_exceeded");
        _;
    }

    enum Vote{
        YAY, //yay = 0
        NAY // nay = 1
    }

    function voteOnProposal (uint256 proposalIndex,Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;
        //calculate how many nfts are owned by the voter 
        //that havent been used for voting on this proposal.
        for(uint256 i = 0 ; i< voterNFTBalance ; i++){
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender,i);
            if(proposal.voters[tokenId] == false){
                numVotes ++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0 ,"Already Voted");
        if(vote == Vote.YAY){
            proposal.yayVotes +=numVotes;
        }else {
            proposal.nayVotes +=numVotes;
        }
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadline <= block.timestamp,"Deadline not exceeded");
        require(proposals[proposalIndex].executed == false,"Proposal already executed");
        _;
    }

    function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly( proposalIndex){

        Proposal storage proposal = proposals[proposalIndex];

        if(proposal.yayVotes > proposal.nayVotes){
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice,"Not Enough Fund");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;

    }

    function withdrawEther() external onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, "Nothing to withdraw, contract balance empty");
    (bool sent, ) = payable(owner()).call{value: amount}("");
    require(sent, "FAILED_TO_WITHDRAW_ETHER");
}
receive() external payable{}
fallback() external payable{}

}