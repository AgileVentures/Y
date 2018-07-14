pragma solidity 0.4.19;

contract Y2 {
    address owner;
    mapping(address => Proportion) donationProportion;
    struct Proportion {
        uint num; // numerator
        uint denom; // denominator
    } // e.g. 25% (25/100, or 0.25) is represented as Proportion(25, 100)

    function Y2() public {
        owner = msg.sender;
    }

    function payAndDonate(address payee, address donee, uint num, uint denom) external payable returns (bool success) {
        require(num == donationProportion[payee].num && denom == donationProportion[payee].denom);
        require((msg.value * donationProportion[payee].num) / msg.value == donationProportion[payee].num); // OpenZeppelin
        uint donation = (msg.value * donationProportion[payee].num) / donationProportion[payee].denom;
        payee.transfer(msg.value - donation); // won't underflow, donation always <= msg.value
        donee.transfer(donation);
        return true;
    }

    function setDonationProportion(uint num, uint denom) external {
        require(0 < num && num < denom); // 0% < num/denom < 100%
        donationProportion[msg.sender] = Proportion(num, denom);
    }

    function getDonationProportion(address payee) external view returns (uint num, uint denom) {
        require(0 < donationProportion[payee].num && donationProportion[payee].num < donationProportion[payee].denom); // 0% < num/denom < 100%
        return (donationProportion[payee].num, donationProportion[payee].denom);
    }

    // only needed if wei gets stuck, though that is not expected
    function unstickWei(address recipient, uint wei_) external {
        require(msg.sender == owner);
        recipient.transfer(wei_);
    }

    // function stickWei() external payable {} // only for testing unstickWei
}
