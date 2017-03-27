using System;
using NUnit.Framework;
using OpenQA.Selenium;

namespace SeleniumParallelTest
{
    [TestFixture]
    public class FirefoxTesting : Hooks
    {
        [Test]
        public void FirefoxGoogleTest()
        {
            Driver.Navigate().GoToUrl("http://www.google.com");
            Driver.FindElement(By.Name("q")).SendKeys("Kamal Chauhan");
            Driver.FindElement(By.Name("btnG")).Click();
            Assert.That(Driver.PageSource.Contains("Kamal Chauhan"), Is.EqualTo(true),
                                                "The text Kamal Chauhan doesnt exist");
        }
    }

    [TestFixture]
    public class ChromeTesting : Hooks
    {
        [Test]
        public void ChromeGoogleTesting()
        {
            Driver.Navigate().GoToUrl("http://www.google.com");
            Driver.FindElement(By.Name("q")).SendKeys("Devops");
            Driver.FindElement(By.Name("btnG")).Click();
            Assert.That(Driver.PageSource.Contains("Devops"), Is.EqualTo(true),
                                                "The text Devops doesnt exist");
        }
    }
}
